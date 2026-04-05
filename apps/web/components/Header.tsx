'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuthStore } from '@/store/useAuthStore'
import { useLocationStore } from '@/store/useLocationStore'
import { createClient } from '@/lib/supabase/browser'
import { AuthModal } from './AuthModal'
import { NotificationToggle } from './NotificationToggle'
import { CitySelector } from './CitySelector'

export function Header() {
  const { user } = useAuthStore()
  const { cityLabel, isDetecting } = useLocationStore()
  const [showAuth, setShowAuth] = useState(false)
  const [showCity, setShowCity] = useState(false)
  const pathname = usePathname()

  async function handleSignOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
  }

  return (
    <>
      <header className="w-full flex items-center justify-between px-6 py-4">
        <div className="flex items-center gap-4">
          <Link href="/" className="text-sm font-bold text-gray-900 hover:text-gray-600 transition-colors">
            陌生城市漫步卡
          </Link>
          {user && (
            <Link
              href="/log"
              className={`text-xs font-medium transition-colors ${
                pathname === '/log' ? 'text-gray-900' : 'text-gray-400 hover:text-gray-700'
              }`}
            >
              漫步日志
            </Link>
          )}
          <button
            onClick={() => setShowCity(true)}
            className="flex items-center gap-1 text-xs text-gray-500 hover:text-gray-800 transition-colors"
          >
            {isDetecting
              ? <span className="w-3 h-3 border-2 border-gray-300 border-t-gray-500 rounded-full animate-spin" />
              : '📍'}
            <span>{cityLabel ?? '选择城市'}</span>
          </button>
        </div>

        {user ? (
          <div className="flex items-center gap-3">
            <NotificationToggle />
            <span className="text-xs text-gray-400 hidden sm:block">{user.email}</span>
            <button
              onClick={handleSignOut}
              className="text-xs text-gray-500 hover:text-gray-800 px-3 py-1.5 rounded-lg hover:bg-gray-100 transition-all"
            >
              退出
            </button>
          </div>
        ) : (
          <button
            onClick={() => setShowAuth(true)}
            className="text-xs font-semibold text-gray-700 px-4 py-2 rounded-xl border border-gray-200 hover:border-gray-400 hover:text-gray-900 transition-all"
          >
            登录 / 注册
          </button>
        )}
      </header>

      <AuthModal isOpen={showAuth} onClose={() => setShowAuth(false)} />
      <CitySelector isOpen={showCity} onClose={() => setShowCity(false)} />
    </>
  )
}
