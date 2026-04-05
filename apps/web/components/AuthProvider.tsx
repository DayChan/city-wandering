'use client'

import { useEffect } from 'react'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { setUser, setIsLoading } = useAuthStore()

  useEffect(() => {
    // 注册 Service Worker（用于 Web Push）
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {})
    }

    const supabase = createClient()

    // 初始化时获取当前 session
    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user)
      setIsLoading(false)
    })

    // 监听登录/退出事件
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [setUser, setIsLoading])

  return <>{children}</>
}
