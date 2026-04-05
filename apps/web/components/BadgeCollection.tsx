'use client'

import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'
import { BADGES } from '@/lib/badges'

export function BadgeCollection() {
  const { user } = useAuthStore()
  const [earnedIds, setEarnedIds] = useState<Set<string>>(new Set())
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!user) return
    setLoading(true)
    const supabase = createClient()
    supabase
      .from('user_badges')
      .select('badge_id')
      .eq('user_id', user.id)
      .then(({ data }) => {
        setEarnedIds(new Set((data ?? []).map((r) => r.badge_id)))
        setLoading(false)
      })
  }, [user])

  if (!user) return null

  const earnedCount = earnedIds.size

  return (
    <div className="w-full max-w-sm">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between px-4 py-3 rounded-2xl bg-white border border-gray-100 hover:border-gray-300 transition-all shadow-sm"
      >
        <div className="flex items-center gap-2">
          <span className="text-base">🏅</span>
          <span className="text-sm font-semibold text-gray-800">城市碎片</span>
          <span className="text-xs text-gray-400">{earnedCount} / {BADGES.length}</span>
        </div>
        <motion.span
          animate={{ rotate: open ? 180 : 0 }}
          transition={{ duration: 0.2 }}
          className="text-gray-400 text-sm"
        >▾</motion.span>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
            style={{ overflow: 'hidden' }}
          >
            <div className="mt-2 p-4 bg-white rounded-2xl border border-gray-100 shadow-sm grid grid-cols-3 gap-3">
              {loading ? (
                <div className="col-span-3 text-center text-xs text-gray-300 py-4">加载中…</div>
              ) : (
                BADGES.map((badge) => {
                  const earned = earnedIds.has(badge.id)
                  return (
                    <div
                      key={badge.id}
                      title={earned ? badge.desc : '尚未解锁'}
                      className={`flex flex-col items-center gap-1.5 p-2 rounded-2xl transition-all ${
                        earned ? badge.color : 'bg-gray-50'
                      }`}
                    >
                      <span className={`text-2xl ${earned ? '' : 'grayscale opacity-30'}`}>
                        {badge.emoji}
                      </span>
                      <span className={`text-[10px] text-center leading-tight font-medium ${
                        earned ? 'text-gray-700' : 'text-gray-300'
                      }`}>
                        {badge.name}
                      </span>
                    </div>
                  )
                })
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
