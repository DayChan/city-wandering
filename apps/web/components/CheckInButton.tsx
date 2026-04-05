'use client'

import { useState } from 'react'
import { useAuthStore } from '@/store/useAuthStore'
import { useCardStore } from '@/store/useCardStore'
import { CheckInModal } from './CheckInModal'

export function CheckInButton() {
  const { user } = useAuthStore()
  const { currentCard, isFlipped } = useCardStore()
  const [showModal, setShowModal] = useState(false)

  // 只在卡片已翻转（查看过冷知识）时出现
  if (!currentCard || !isFlipped) return null

  if (!user) {
    return (
      <p className="text-xs text-gray-400 text-center">
        <span>登录后可以打卡记录 ✓</span>
      </p>
    )
  }

  return (
    <>
      <button
        onClick={() => setShowModal(true)}
        className="flex items-center gap-2 px-6 py-3 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-white text-sm font-semibold active:scale-95 transition-all shadow-md"
      >
        <span>✓</span>
        <span>完成任务，打个卡</span>
      </button>

      <CheckInModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        card={currentCard}
      />
    </>
  )
}
