// Supabase Edge Function. Invocar mediante Database Webhook en INSERT de notifications.
// El secreto del webhook es independiente de la clave service role.
import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
Deno.serve(async (req: Request) => {
  const secret = Deno.env.get('NOTIFICATION_WEBHOOK_SECRET');
  if (!secret || req.headers.get('x-webhook-secret') !== secret) return new Response('Unauthorized', { status: 401 });
  if(req.method!=='POST')return new Response('Method not allowed',{status:405});
  try {
    const event = await req.json();
    if (event.type !== 'INSERT' || event.table !== 'notifications' || !event.record?.id) return new Response('Invalid event', { status: 400 });
    const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const {data:n,error}=await db.from('notifications').select('id,user_id,body').eq('id',event.record.id).single();
    if(error)throw error;
    const {data:p}=await db.from('profiles').select('email_notifications,suspended').eq('id',n.user_id).single();
    if(!p?.email_notifications||p.suspended)return new Response('Skipped');
    const {data:u,error:userError}=await db.auth.admin.getUserById(n.user_id);
    if(userError)throw userError;
    const response=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${Deno.env.get('RESEND_API_KEY')}`,'Content-Type':'application/json','Idempotency-Key':`notification-${n.id}`},body:JSON.stringify({from:Deno.env.get('MAIL_FROM'),to:[u.user.email],subject:'Novedades de tu cuenta · MAVI\'S SHOP',text:`${n.body}\n\nRevisa tu cuenta: ${Deno.env.get('SITE_URL')}\nPuedes desactivar estos correos desde Mi perfil.`})});
    if(!response.ok)throw Error('Email provider error');
    return new Response('Sent');
  }catch{ return new Response('Could not send notification; retry this event.',{status:500}); }
});
