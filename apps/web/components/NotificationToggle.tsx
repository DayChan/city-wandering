'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'

function urlBase64ToUint8Array(base64: string) {
  const padding = '='.repeat((4 - (base64.length % 4)) % 4)
  const b64 = (base64 + padding).replace(/-/g, '+').replace(/_/g, '/')
  const raw = atob(b64)
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
}

export function NotificationToggle() {
  const { user } = useAuthStore()
  const [supported, setSupported] = useState(false)
  const [enabled, setEnabled] = useState(false)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const ok =
      typeof window !== 'undefined' &&
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window
    setSupported(ok)
    if (!ok) return

    navigator.serviceWorker.ready.then((reg) =>
      reg.pushManager.getSubscription().then((sub) => setEnabled(!!sub))
    )
  }, [])

  if (!supported || !user) return null

  async function toggle() {
    setLoading(true)
    try {
      const supabase = createClient()
      const reg = await navigator.serviceWorker.ready

      if (enabled) {
        const sub = await reg.pushManager.getSubscription()
        if (sub) {
          await sub.unsubscribe()
          await supabase.from('push_subscriptions').delete().eq('endpoint', sub.endpoint)
        }
        setEnabled(false)
      } else {
        // 请求通知权限
        const permission = await Notification.requestPermission()
        if (permission !== 'granted') return

        const vapidKey = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY
        if (!vapidKey) { console.error('NEXT_PUBLIC_VAPID_PUBLIC_KEY not set'); return }

        const sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(vapidKey),
        })
        const json = sub.toJSON()
        await supabase.from('push_subscriptions').upsert(
          {
            user_id: user!.id,
            endpoint: sub.endpoint,
            p256dh: json.keys!.p256dh,
            auth_key: json.keys!.auth,
          },
          { onConflict: 'endpoint' }
        )
        setEnabled(true)
      }
    } catch (e) {
      console.error('Push toggle error:', e)
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={toggle}
      disabled={loading}
      title={enabled ? '关闭社区通知' : '开启社区通知'}
      className={`text-base transition-all disabled:opacity-40 ${
        enabled ? 'opacity-100' : 'opacity-40 hover:opacity-70'
      }`}
    >
      {enabled ? '🔔' : '🔕'}
    </button>
  )
}
