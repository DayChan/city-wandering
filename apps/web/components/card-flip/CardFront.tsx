import { Card, THEME_LABELS, THEME_EMOJIS, THEME_GRADIENTS } from '@/lib/types'

const DIFFICULTY_STARS = { 1: '★☆☆', 2: '★★☆', 3: '★★★' } as const

interface CardFrontProps {
  card: Card
}

export function CardFront({ card }: CardFrontProps) {
  const gradient = THEME_GRADIENTS[card.theme]

  return (
    <div id="card-capture" className={`w-full h-full rounded-3xl bg-gradient-to-br ${gradient} flex flex-col p-7 shadow-2xl`}>
      {/* 顶部行 */}
      <div className="flex items-start justify-between">
        <div className="flex flex-col gap-1">
          <span className="text-3xl">{THEME_EMOJIS[card.theme]}</span>
          <span className="text-white/80 text-xs font-semibold tracking-widest uppercase">
            {THEME_LABELS[card.theme]}
          </span>
        </div>
        <div className="flex flex-col items-end gap-1">
          <span className="text-white/60 text-xs font-medium">难度</span>
          <span className="text-white text-base tracking-widest">
            {DIFFICULTY_STARS[card.difficulty]}
          </span>
        </div>
      </div>

      {/* 任务描述 */}
      <div className="flex-1 flex items-center justify-center py-6">
        <p className="text-white text-2xl font-bold text-center leading-relaxed drop-shadow-sm">
          {card.title}
        </p>
      </div>

      {/* 底部 */}
      <div className="flex items-center justify-between">
        {card.city !== 'universal' ? (
          <span className="bg-white/20 text-white text-xs px-3 py-1 rounded-full">
            📍 {card.city}
          </span>
        ) : (
          <span className="bg-white/20 text-white text-xs px-3 py-1 rounded-full">
            🌍 通用
          </span>
        )}
        <span className="text-white/60 text-xs">点击翻转 →</span>
      </div>
    </div>
  )
}
