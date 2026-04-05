'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { CardFlip } from '@/components/card-flip/CardFlip'
import { ThemeFilter } from '@/components/ThemeFilter'
import { DrawButton } from '@/components/DrawButton'
import { ShareButton } from '@/components/ShareButton'
import { CheckInButton } from '@/components/CheckInButton'
import { useCardStore } from '@/store/useCardStore'
import { BadgeCollection } from '@/components/BadgeCollection'

export default function Home() {
  const { currentCard, error } = useCardStore()

  return (
    <main className="flex-1 flex flex-col items-center px-4 py-8 gap-8">

      {/* 副标题 */}
      <p className="text-gray-400 text-sm">选一个主题，抽一张卡，开始今天的探索</p>

      {/* 主题筛选 */}
      <ThemeFilter />

      {/* 卡片区域 */}
      <div className="flex flex-col items-center gap-6">
        <AnimatePresence mode="wait">
          {currentCard ? (
            <motion.div
              key={currentCard.id}
              initial={{ opacity: 0, y: 24, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -16, scale: 0.96 }}
              transition={{ duration: 0.35, ease: [0.4, 0, 0.2, 1] }}
            >
              <CardFlip />
            </motion.div>
          ) : (
            <motion.div
              key="empty"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="w-[320px] h-[480px] rounded-3xl border-2 border-dashed border-gray-200 flex flex-col items-center justify-center gap-3 text-gray-300"
            >
              <span className="text-5xl">🎴</span>
              <span className="text-sm">点击下方按钮抽一张卡</span>
            </motion.div>
          )}
        </AnimatePresence>

        {/* 打卡按钮（翻转后出现） */}
        <CheckInButton />

        {/* 操作按钮行 */}
        <div className="flex items-center gap-3">
          <DrawButton />
          <ShareButton />
        </div>

        {/* 错误提示 */}
        {error && (
          <p className="text-red-400 text-sm bg-red-50 px-4 py-2 rounded-xl">{error}</p>
        )}
      </div>

      {/* 城市碎片徽章 */}
      <BadgeCollection />

      {/* Footer */}
      <p className="mt-auto text-xs text-gray-300 pb-4">
        陌生城市漫步卡 · MVP
      </p>
    </main>
  )
}
