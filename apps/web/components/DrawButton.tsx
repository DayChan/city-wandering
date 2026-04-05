'use client'

import { useCardStore } from '@/store/useCardStore'
import { cardApi } from '@/lib/api'

export function DrawButton() {
  const { selectedTheme, currentCard, isLoading, setCurrentCard, setIsLoading, setError } =
    useCardStore()

  async function handleDraw() {
    setIsLoading(true)
    setError(null)
    try {
      const card = await cardApi.getRandom({ theme: selectedTheme ?? undefined })
      setCurrentCard(card)
    } catch (e) {
      setError(e instanceof Error ? e.message : '抽卡失败，请重试')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <button
      onClick={handleDraw}
      disabled={isLoading}
      className="
        relative px-6 py-3 rounded-2xl text-sm font-semibold text-white
        bg-gray-900 hover:bg-gray-700 active:scale-95
        transition-all duration-200 shadow-lg
        disabled:opacity-50 disabled:cursor-not-allowed
      "
    >
      {isLoading ? (
        <span className="flex items-center gap-2">
          <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          抽取中…
        </span>
      ) : currentCard ? (
        '再抽一张'
      ) : (
        '🎴 抽一张'
      )}
    </button>
  )
}
