import { Hono } from 'hono'
import webpush from 'web-push'
import { createClient } from '@supabase/supabase-js'
import type { Env } from '../index'

const push = new Hono<{ Bindings: Env }>()

// POST /push/notify — 打卡成功后通知其他订阅用户
push.post('/notify', async (c) => {
  // 验证调用方是已登录用户（通过 Supabase JWT）
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'Unauthorized' }, 401)

  const supabase = createClient(c.env.SUPABASE_URL, c.env.SUPABASE_SERVICE_ROLE_KEY)

  // 验证 token，获取 user_id
  const { data: { user }, error: authErr } = await supabase.auth.getUser(token)
  if (authErr || !user) return c.json({ error: 'Invalid token' }, 401)

  const body = await c.req.json<{ title: string; body: string; url?: string }>()

  // 拉取除自己以外的所有订阅
  const { data: subs } = await supabase
    .from('push_subscriptions')
    .select('endpoint, p256dh, auth_key')
    .neq('user_id', user.id)

  if (!subs || subs.length === 0) return c.json({ sent: 0 })

  webpush.setVapidDetails(
    c.env.VAPID_SUBJECT,
    c.env.VAPID_PUBLIC_KEY,
    c.env.VAPID_PRIVATE_KEY,
  )

  const payload = JSON.stringify({ title: body.title, body: body.body, url: body.url ?? '/log' })

  const results = await Promise.allSettled(
    subs.map((sub) =>
      webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth_key } },
        payload,
      )
    )
  )

  // 删除失效订阅（410 Gone）
  const failedEndpoints = subs
    .filter((_, i) => results[i].status === 'rejected')
    .map((s) => s.endpoint)

  if (failedEndpoints.length > 0) {
    await supabase.from('push_subscriptions').delete().in('endpoint', failedEndpoints)
  }

  return c.json({ sent: results.filter((r) => r.status === 'fulfilled').length })
})

export { push }
