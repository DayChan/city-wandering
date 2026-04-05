'use client'

import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'
import { WalkLogCard } from '@/components/WalkLogCard'
import { THEME_LABELS, THEME_EMOJIS } from '@/lib/types'
import type { CheckInRecord } from '@/components/WalkLogCard'
import type { Theme } from '@/lib/types'

type Tab = 'mine' | 'community'

const THEMES: Theme[] = ['food', 'architecture', 'culture', 'nature', 'color-walk', 'random']

export default function LogPage() {
  const { user } = useAuthStore()
  const [tab, setTab] = useState<Tab>('mine')
  const [theme, setTheme] = useState<Theme | null>(null)
  const [records, setRecords] = useState<CheckInRecord[]>([])
  const [profileMap, setProfileMap] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!user) return
    setLoading(true)
    setRecords([])
    setProfileMap({})

    const supabase = createClient()

    async function fetch() {
      let q = supabase
        .from('check_ins')
        .select('id, user_id, photo_url, note, created_at, cards!inner(title, theme)')
        .order('created_at', { ascending: false })
        .limit(40)

      if (tab === 'mine') q = q.eq('user_id', user!.id)
      if (theme) q = q.eq('cards.theme', theme)

      const { data } = await q
      const rows = (data ?? []) as unknown as CheckInRecord[]
      setRecords(rows)

      // 社区模式：批量拉取 profiles
      if (tab === 'community' && rows.length > 0) {
        const userIds = [...new Set(rows.map((r) => r.user_id))]
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, display_name')
          .in('id', userIds)

        const map: Record<string, string> = {}
        for (const p of profiles ?? []) map[p.id] = p.display_name
        setProfileMap(map)
      }

      setLoading(false)
    }

    fetch()
  }, [user, tab, theme])

  if (!user) {
    return (
      <main className="flex-1 flex flex-col items-center justify-center px-4 py-16 gap-4">
        <span className="text-4xl">🗺️</span>
        <p className="text-gray-400 text-sm">登录后查看漫步日志</p>
      </main>
    )
  }

  return (
    <main className="flex-1 flex flex-col items-center px-4 py-8 gap-6">
      <div className="w-full max-w-sm">
        <h1 className="text-lg font-bold text-gray-900 mb-5">漫步日志</h1>

        {/* Tab 切换 */}
        <div className="relative flex bg-gray-100 rounded-2xl p-1 mb-4">
          {(['mine', 'community'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className="relative flex-1 py-2 text-sm font-medium z-10 transition-colors"
              style={{ color: tab === t ? '#111' : '#9ca3af' }}
            >
              {t === 'mine' ? '我的日志' : '社区广场'}
              {tab === t && (
                <motion.div
                  layoutId="tab-bg"
                  className="absolute inset-0 bg-white rounded-xl shadow-sm"
                  style={{ zIndex: -1 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}
            </button>
          ))}
        </div>

        {/* 主题过滤标签 */}
        <div className="flex gap-2 overflow-x-auto pb-1 mb-5 no-scrollbar">
          <button
            onClick={() => setTheme(null)}
            className={`shrink-0 text-xs font-medium px-3 py-1.5 rounded-full border transition-all ${
              theme === null
                ? 'bg-gray-900 text-white border-gray-900'
                : 'bg-white text-gray-500 border-gray-200 hover:border-gray-400'
            }`}
          >
            全部
          </button>
          {THEMES.map((t) => (
            <button
              key={t}
              onClick={() => setTheme(theme === t ? null : t)}
              className={`shrink-0 text-xs font-medium px-3 py-1.5 rounded-full border transition-all ${
                theme === t
                  ? 'bg-gray-900 text-white border-gray-900'
                  : 'bg-white text-gray-500 border-gray-200 hover:border-gray-400'
              }`}
            >
              {THEME_EMOJIS[t]} {THEME_LABELS[t]}
            </button>
          ))}
        </div>

        {/* 内容区 */}
        <AnimatePresence mode="wait">
          {loading ? (
            <motion.div
              key="loading"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex flex-col items-center justify-center py-16 gap-3 text-gray-300"
            >
              <span className="w-6 h-6 border-2 border-gray-200 border-t-gray-400 rounded-full animate-spin" />
              <span className="text-xs">加载中…</span>
            </motion.div>
          ) : records.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex flex-col items-center justify-center py-16 gap-3 text-gray-300"
            >
              <span className="text-4xl">{tab === 'mine' ? '🚶' : '🌆'}</span>
              <span className="text-sm">
                {tab === 'mine' ? '还没有打卡记录，出发吧！' : '暂无打卡分享'}
              </span>
            </motion.div>
          ) : (
            <motion.div
              key={`${tab}-${theme}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex flex-col gap-4"
            >
              {records.map((r, i) => (
                <WalkLogCard
                  key={r.id}
                  record={r}
                  displayName={profileMap[r.user_id]}
                  showUser={tab === 'community'}
                  index={i}
                />
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </main>
  )
}
