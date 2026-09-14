-- SOLO SI YA INSTALASTE LA VERSION ANTERIOR. No recrea tablas ni borra datos.
-- Ejecutar en Supabase SQL Editor. Puede repetirse.
begin;
alter table public.settings alter column name set default 'MAVI''S SHOP';
update public.settings set name='MAVI''S SHOP' where id=1;
create or replace function public.mutate(op text, payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare u uuid:=auth.uid(); p profiles; x products; o orders; c conversations; rid uuid; target uuid; obj jsonb; line jsonb; v jsonb; arr jsonb; snapshot jsonb; cp coupons; discount_amount numeric; result jsonb:='[]'; n int; qty int; idx int; tot numeric; st text; admin boolean; begin
if u is null or not active() then raise exception 'Debes iniciar sesión con una cuenta activa'; end if;
admin:=is_admin();
if op='profile' then
 if length(trim(payload->>'name')) not between 1 and 100 or (payload->>'phone') !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'Nombre o teléfono internacional inválido. Ejemplo: +50760000000'; end if;
 update profiles set name=trim(payload->>'name'),phone=payload->>'phone',bio=left(coalesce(payload->>'bio',''),2000),avatar=coalesce(payload->>'avatar',''),vacation=coalesce((payload->>'vacation')::boolean,false),notifications=coalesce((payload->>'notifications')::boolean,true),email_notifications=coalesce((payload->>'email_notifications')::boolean,false) where id=u;
elsif op='product' then
 if (select vacation from profiles where id=u) then raise exception 'Desactiva vacaciones para publicar'; end if;
 rid:=coalesce(nullif(payload->>'id','')::uuid,gen_random_uuid()); select * into x from products where id=rid for update;
 if found and x.seller_id<>u and not admin then raise exception 'Producto ajeno'; end if;
 if length(trim(payload->>'name')) not between 1 and 160 or (payload->>'price')::numeric<=0 or jsonb_array_length(payload->'variants')<1 then raise exception 'Completa nombre, precio y variantes'; end if;
 if not exists(select 1 from settings where payload->>'category'=any(categories)) then raise exception 'Categoría inválida'; end if;
 for v in select value from jsonb_array_elements(payload->'variants') loop
 if coalesce(v->>'name','')='' or v->>'stock' is null or (v->>'stock')::int<0 or (v->>'stock')::numeric<>(v->>'stock')::int then raise exception 'Variante o inventario inválido'; end if; end loop;
 if (select count(*) from jsonb_array_elements(payload->'variants'))<>(select count(distinct value->>'name') from jsonb_array_elements(payload->'variants')) then raise exception 'Las variantes deben tener nombres distintos'; end if;
 -- Evita que una edición invalide reservas de pedidos ya aceptados.
 if x.id is not null and exists(select 1 from orders z,jsonb_array_elements(z.items) a where z.status in('accepted','paid','shipped') and a->>'product_id'=rid::text) then raise exception 'Hay pedidos reservados. Completa o cancela esos pedidos antes de editar'; end if;
 st:=coalesce(payload->>'status','pending'); if st not in('draft','pending','paused','archived') then raise exception 'Estado inválido'; end if;
 if st='pending' and (admin or not(select approval from settings where id=1)) then st:='approved'; end if;
 insert into products(id,seller_id,name,description,category,brand,price,previous_price,shipping,warranty,specs,images,variants,status) values(rid,coalesce(x.seller_id,u),trim(payload->>'name'),coalesce(payload->>'description',''),payload->>'category',coalesce(payload->>'brand',''),(payload->>'price')::numeric,nullif(payload->>'previous_price','')::numeric,coalesce(payload->>'shipping',''),coalesce(payload->>'warranty',''),coalesce(payload->>'specs',''),array(select jsonb_array_elements_text(coalesce(payload->'images','[]'))),payload->'variants',st)
 on conflict(id) do update set name=excluded.name,description=excluded.description,category=excluded.category,brand=excluded.brand,price=excluded.price,previous_price=excluded.previous_price,shipping=excluded.shipping,warranty=excluded.warranty,specs=excluded.specs,images=excluded.images,variants=excluded.variants,status=excluded.status;
 if st='pending' then perform notify((select user_id from administrators),'Nueva publicación pendiente de aprobación'); end if;
 return jsonb_build_object('id',rid);
elsif op='coupon' then
 rid:=coalesce(nullif(payload->>'id','')::uuid,gen_random_uuid());
 if exists(select 1 from coupons where id=rid and seller_id<>u) and not admin then raise exception 'Cupón ajeno'; end if;
 insert into coupons(id,seller_id,code,percent,expires_at,enabled) values(rid,u,upper(trim(payload->>'code')),(payload->>'percent')::int,(payload->>'expires_at')::timestamptz,coalesce((payload->>'enabled')::boolean,true)) on conflict(id) do update set enabled=excluded.enabled;
 elsif op='favorite' then
 rid:=(payload->>'id')::uuid; if exists(select 1 from favorites where user_id=u and product_id=rid) then delete from favorites where user_id=u and product_id=rid; else insert into favorites values(u,rid); end if;
elsif op='orders' then
 if jsonb_array_length(payload->'items') not between 1 and 100 then raise exception 'Carrito inválido'; end if;
 if exists(select 1 from jsonb_array_elements(payload->'items') a where not exists(select 1 from products where id=(a->>'product_id')::uuid)) then raise exception 'Hay productos que ya no existen'; end if;
 -- Una transacción para todo el carrito. Los datos y precios se leen del servidor.
 for target in select distinct z.seller_id from products z join jsonb_array_elements(payload->'items') a on z.id=(a->>'product_id')::uuid order by z.seller_id loop
 if target=u then raise exception 'No puedes comprar tus propios productos'; end if;
 if exists(select 1 from profiles where id=target and (vacation or suspended)) then raise exception 'Vendedor no disponible'; end if;
 snapshot:='[]'; tot:=0;
 for line in select a from jsonb_array_elements(payload->'items') a join products z on z.id=(a->>'product_id')::uuid where z.seller_id=target order by z.id loop
 select * into x from products where id=(line->>'product_id')::uuid for update;
 qty:=(line->>'quantity')::int; if qty<1 or qty>999 or (line->>'quantity')::numeric<>qty or x.status<>'approved' then raise exception 'Producto o cantidad inválidos'; end if;
 select value into v from jsonb_array_elements(x.variants) where value->>'name'=line->>'variant';
 if v is null or (v->>'stock')::int<qty then raise exception 'No hay existencias suficientes para %',x.name; end if;
 snapshot:=snapshot||jsonb_build_array(jsonb_build_object('product_id',x.id,'name',x.name,'variant',v->>'name','quantity',qty,'price',x.price)); tot:=tot+x.price*qty;
 end loop;
 discount_amount:=0; cp:=null;
 if coalesce(payload->>'coupon','')<>'' then select * into cp from coupons where seller_id=target and code=upper(payload->>'coupon') and enabled and expires_at>now(); if cp.id is not null then discount_amount:=round(tot*cp.percent/100,2); end if; end if;
 insert into orders(buyer_id,seller_id,items,total,discount,coupon,note) values(u,target,snapshot,tot-discount_amount,discount_amount,coalesce(cp.code,''),left(coalesce(payload->>'note',''),2000)) returning id into rid;
 insert into order_events(order_id,actor,status) values(rid,u,'pending'); perform notify(target,'Nueva solicitud de pedido '||left(rid::text,8)); result:=result||jsonb_build_array(rid);
 end loop;
 if result='[]' then raise exception 'El carrito no contiene productos disponibles'; end if; return result;
elsif op='order_status' then
 select * into o from orders where id=(payload->>'id')::uuid for update;
 if o.id is null or (u not in(o.buyer_id,o.seller_id) and not admin) then raise exception 'Pedido no autorizado'; end if;
 st:=payload->>'status';
 if not ((st='accepted' and o.status='pending' and (u=o.seller_id or admin)) or (st='paid' and o.status='accepted' and (u=o.seller_id or admin)) or (st='shipped' and o.status='paid' and (u=o.seller_id or admin)) or (st='delivered' and o.status in('paid','shipped')) or (st='cancelled' and ((o.status='pending') or (o.status='accepted' and (u=o.seller_id or admin))))) then raise exception 'Cambio de estado no permitido. Los pagos confirmados se resuelven mediante devolución'; end if;
 if st='accepted' and exists(select 1 from profiles where id=o.seller_id and (suspended or vacation)) then raise exception 'Vendedor no disponible'; end if;
 if st='accepted' or (st='cancelled' and o.status='accepted') then
 for line in select value from jsonb_array_elements(o.items) order by value->>'product_id' loop
 select * into x from products where id=(line->>'product_id')::uuid for update;
 idx:=null; select (ordinality-1)::int,value into idx,v from jsonb_array_elements(x.variants) with ordinality where value->>'name'=line->>'variant';
 if idx is null then raise exception 'La variante ya no existe'; end if;
 qty:=(line->>'quantity')::int; n:=(v->>'stock')::int;
 if st='accepted' then if x.status<>'approved' or n<qty then raise exception 'Producto no disponible o inventario insuficiente'; end if; n:=n-qty; else n:=n+qty; end if;
 update products set variants=jsonb_set(variants,array[idx::text,'stock'],to_jsonb(n)) where id=x.id;
 if st='accepted' and n<=3 then perform notify(x.seller_id,'Inventario bajo: '||x.name||' / '||(line->>'variant')||' ('||n||' disponibles)'); end if;
 end loop; end if;
 update orders set status=st,tracking=coalesce(payload->>'tracking',tracking) where id=o.id;
 insert into order_events(order_id,actor,status) values(o.id,u,st); perform notify(case when u=o.buyer_id then o.seller_id else o.buyer_id end,'Pedido '||left(o.id::text,8)||': '||st);
elsif op='order_costs' then
 select * into o from orders where id=(payload->>'id')::uuid for update;
 if o.id is null or (o.seller_id<>u and not admin) or o.status<>'pending' then raise exception 'Solo se ajustan costos antes de aceptar'; end if;
 if (payload->>'shipping_fee')::numeric<0 or (payload->>'expenses')::numeric<0 then raise exception 'Costos inválidos'; end if;
 update orders set shipping_fee=(payload->>'shipping_fee')::numeric,expenses=(payload->>'expenses')::numeric where id=o.id;
 perform notify(o.buyer_id,'Se actualizó el envío de tu pedido. Revisa el total antes de pagar.');
elsif op='review' then
 select * into o from orders where id=(payload->>'order_id')::uuid;
 if o.buyer_id<>u or o.status<>'delivered' or o.id is null then raise exception 'Solo puedes reseñar tus pedidos entregados'; end if;
 insert into reviews(order_id,buyer_id,seller_id,rating,body) values(o.id,u,o.seller_id,(payload->>'rating')::int,payload->>'body');
elsif op='chat' then
 select * into x from products where id=(payload->>'product_id')::uuid and status='approved';
 if x.id is null or x.seller_id=u or exists(select 1 from profiles where id=x.seller_id and suspended) then raise exception 'Conversación no disponible'; end if;
 if exists(select 1 from blocks where (user_id=u and blocked_id=x.seller_id) or (user_id=x.seller_id and blocked_id=u)) then raise exception 'Contacto bloqueado'; end if;
 insert into conversations(buyer_id,seller_id,product_id) values(u,x.seller_id,x.id) on conflict(buyer_id,seller_id,product_id) do update set product_id=excluded.product_id returning id into rid; return jsonb_build_object('id',rid);
elsif op='message' then
 rid:=(payload->>'conversation_id')::uuid; select * into c from conversations where id=rid;
 if not member_of(rid) then raise exception 'Conversación privada'; end if;
 target:=case when u=c.buyer_id then c.seller_id else c.buyer_id end;
 if exists(select 1 from profiles where id=target and suspended) or exists(select 1 from blocks where(user_id=u and blocked_id=target)or(user_id=target and blocked_id=u)) then raise exception 'Contacto no disponible'; end if;
 if exists(select 1 from messages where sender_id=u and created_at>now()-interval '1 second') then raise exception 'Espera un segundo entre mensajes'; end if;
 if coalesce(payload->>'image','')<>'' and (payload->>'image') not like (rid::text||'/'||u::text||'/%') then raise exception 'Imagen inválida'; end if;
 insert into messages(conversation_id,sender_id,body,image) values(rid,u,trim(coalesce(payload->>'body','')),coalesce(payload->>'image',''));
 perform notify(target,'Nuevo mensaje en MAVI''S SHOP');
elsif op='read' then
 update notifications set read_at=now() where user_id=u;
 if payload ? 'conversation_id' and member_of((payload->>'conversation_id')::uuid) then update messages set read_at=now() where conversation_id=(payload->>'conversation_id')::uuid and sender_id<>u and read_at is null; end if;
elsif op='block' then
 target:=(payload->>'id')::uuid; if exists(select 1 from blocks where user_id=u and blocked_id=target) then delete from blocks where user_id=u and blocked_id=target; else insert into blocks values(u,target); end if;
elsif op='report' then
 rid:=nullif(payload->>'conversation_id','')::uuid;
 if rid is not null and not member_of(rid) then raise exception 'Conversación privada'; end if;
 if payload->>'kind'='return' then select * into o from orders where id=(payload->>'order_id')::uuid; if o.id is null or o.buyer_id<>u or o.status not in('paid','shipped','delivered') then raise exception 'Pedido no elegible para devolución'; end if; end if;
 insert into reports(user_id,target_id,conversation_id,order_id,kind,reason,evidence) values(u,nullif(payload->>'target_id','')::uuid,rid,nullif(payload->>'order_id','')::uuid,payload->>'kind',payload->>'reason',coalesce(payload->>'evidence',''));
elsif op='resolve_return' then
 select order_id into rid from reports where id=(payload->>'id')::uuid and kind='return'; select * into o from orders where id=rid;
 if o.id is null or(o.seller_id<>u and not admin) then raise exception 'Devolución ajena'; end if;
 update reports set status='resolved',resolution=left(payload->>'resolution',4000) where id=(payload->>'id')::uuid; perform notify(o.buyer_id,'El vendedor respondió a tu devolución.');
elsif op like 'admin_%' then
 if not admin then raise exception 'Solo el administrador'; end if;
 if op='admin_user' then
 target:=(payload->>'id')::uuid; if target=u then raise exception 'No puedes suspender tu cuenta administradora'; end if;
 update profiles set suspended=(payload->>'suspended')::boolean,verified=(payload->>'verified')::boolean where id=target;
 elsif op='admin_product' then
 st:=payload->>'status'; if st not in('approved','rejected','paused','archived') then raise exception 'Estado inválido'; end if;
 update products set status=st where id=(payload->>'id')::uuid returning seller_id into target; perform notify(target,'Publicación revisada: '||st);
 elsif op='admin_settings' then
 update settings set name=left(payload->>'name',100),contact=payload->>'contact',policies=payload->>'policies',categories=array(select jsonb_array_elements_text(payload->'categories')),approval=(payload->>'approval')::boolean,logo=coalesce(payload->>'logo','/logo.png') where id=1;
 elsif op='admin_report' then
 update reports set status='resolved',resolution=payload->>'resolution' where id=(payload->>'id')::uuid;
 else raise exception 'Acción administrativa desconocida'; end if;
 insert into audit(actor,action,target) values(u,op,coalesce(payload->>'id','settings'));
else raise exception 'Acción desconocida'; end if;
return jsonb_build_object('ok',true); end$$;


commit;
