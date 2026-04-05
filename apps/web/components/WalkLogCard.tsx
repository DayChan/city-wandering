'use client'

import { motion } from 'framer-motion'
import { THEME_LABELS, THEME_EMOJIS, THEME_COLORS } from '@/lib/types'
import type { Theme } from '@/lib/types'

export interface CheckInRecord {
  id: string
  user_id: string
  photo_url: string | null
  note: string | null
  created_at: string
  cards: {
    title: string
    theme: Theme
  } | null
}

interface WalkLogCardProps {
  record: CheckInRecord
  displayName?: string
  showUser?: boolean
  index?: number
}

function formatDate(iso: string) {
  const d = new Date(iso)
  const now = new Date()
  const diffMs = now.getTime() - d.getTime()
  const diffDays = Math.floor(diffMs / 86400000)
  if (diffDays === 0) return '今天 ' + d.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  if (diffDays === 1) return '昨天'
  if (diffDays < 7) return `${diffDays} 天前`
  return d.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
}

function getInitials(name: string) {
  return name.slice(0, 2).toUpperCase()
}

const AVATAR_COLORS = [
  'bg-orange-200 text-orange-700',
  'bg-blue-200 text-blue-700',
  'bg-green-200 text-green-700',
  'bg-purple-200 text-purple-700',
  'bg-rose-200 text-rose-700',
  'bg-amber-200 text-amber-700',
]

function avatarColor(userId: string) {
  let hash = 0
  for (let i = 0; i < userId.length; i++) hash = (hash * 31 + userId.charCodeAt(i)) & 0xffffffff
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

export function WalkLogCard({ record, displayName, showUser = false, index = 0 }: WalkLogCardProps) {
  const theme = record.cards?.theme
  const emoji = theme ? THEME_EMOJIS[theme] : '🎴'
  const label = theme ? THEME_LABELS[theme] : '未知'
  const tagClass = theme ? THEME_COLORS[theme] : 'bg-gray-100 text-gray-600 border-gray-200'
  const name = displayName ?? '漫游者'

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, delay: index * 0.05, ease: [0.4, 0, 0.2, 1] }}
      className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden"
    >
      {/* 照片 */}
      {record.photo_url && (
        <div className="w-full h-48 overflow-hidden bg-gray-50">
          <img
            src={record.photo_url}
            alt="打卡照片"
            className="w-full h-full object-cover"
          />
        </div>
      )}

      <div className="p-4">
        {/* 用户行（社区模式） */}
        {showUser && (
          <div className="flex items-center gap-2 mb-3">
            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 ${avatarColor(record.user_id)}`}>
              {getInitials(name)}
            </div>
            <span className="text-xs font-medium text-gray-700">{name}</span>
          </div>
        )}

        {/* 主题标签 + 时间 */}
        <div className="flex items-center justify-between mb-2">
          <span className={`inline-flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full border ${tagClass}`}>
            {emoji} {label}
          </span>
          <span className="text-xs text-gray-300">{formatDate(record.created_at)}</span>
        </div>

        {/* 任务标题 */}
        {record.cards?.title && (
          <p className="text-sm text-gray-700 font-medium line-clamp-2 mb-2">
            {record.cards.title}
          </p>
        )}

        {/* 备注 */}
        {record.note && (
          <p className="text-xs text-gray-400 leading-relaxed line-clamp-3 border-t border-gray-50 pt-2 mt-2">
            {record.note}
          </p>
        )}
      </div>
    </motion.div>
  )
}
