'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { BADGE_MAP, type BadgeDef } from '@/lib/badges'

interface BadgeUnlockToastProps {
  badgeIds: string[]
  onDismiss: () => void
}

export function BadgeUnlockToast({ badgeIds, onDismiss }: BadgeUnlockToastProps) {
  const badges = badgeIds.map((id) => BADGE_MAP[id]).filter(Boolean) as BadgeDef[]

  return (
    <AnimatePresence>
      {badges.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 40, scale: 0.9 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 20, scale: 0.9 }}
          transition={{ type: 'spring', stiffness: 300, damping: 24 }}
          className="fixed bottom-8 left-1/2 -translate-x-1/2 z-50 w-[320px]"
        >
          <div className="bg-gray-900 text-white rounded-3xl p-5 shadow-2xl">
            <p className="text-xs font-bold text-amber-400 tracking-widest uppercase mb-3">
              🎖️ 徽章解锁！
            </p>
            <div className="flex flex-col gap-2">
              {badges.map((badge) => (
                <div key={badge.id} className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-2xl ${badge.color} flex items-center justify-center text-xl shrink-0`}>
                    {badge.emoji}
                  </div>
                  <div>
                    <p className="font-semibold text-sm">{badge.name}</p>
                    <p className="text-xs text-gray-400">{badge.desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <button
              onClick={onDismiss}
              className="mt-4 w-full py-2 rounded-2xl bg-white/10 hover:bg-white/20 text-sm font-medium transition-colors"
            >
              太棒了！
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
