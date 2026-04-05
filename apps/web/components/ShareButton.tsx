'use client'

import { useCardStore } from '@/store/useCardStore'

export function ShareButton() {
  const { currentCard } = useCardStore()

  if (!currentCard) return null

  async function handleShare() {
    const el = document.getElementById('card-capture')
    if (!el || !currentCard) return

    try {
      const { toPng } = await import('html-to-image')
      const dataUrl = await toPng(el, {
        pixelRatio: 3,
        skipAutoScale: true,
      })

      const res = await fetch(dataUrl)
      const blob = await res.blob()

      if (navigator.share && navigator.canShare?.({ files: [new File([blob], 'card.png', { type: 'image/png' })] })) {
        await navigator.share({
          files: [new File([blob], '漫步卡.png', { type: 'image/png' })],
          title: '陌生城市漫步卡',
          text: currentCard.title,
        })
      } else {
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `漫步卡-${currentCard.theme}.png`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (e) {
      console.error('分享失败', e)
    }
  }

  return (
    <button
      onClick={handleShare}
      className="
        flex items-center gap-2 px-6 py-3 rounded-2xl text-sm font-medium
        bg-white text-gray-700 border border-gray-200
        hover:border-gray-400 hover:text-gray-900
        active:scale-95 transition-all duration-200 shadow-sm
      "
    >
      <span>↗</span>
      <span>保存 / 分享</span>
    </button>
  )
}
