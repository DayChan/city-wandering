import { Card } from '@/lib/types'

interface CardBackProps {
  card: Card
}

export function CardBack({ card }: CardBackProps) {
  return (
    <div className="w-full h-full rounded-3xl bg-gray-950 flex flex-col p-7 shadow-2xl">
      {/* 顶部 */}
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-amber-400/20 flex items-center justify-center">
          <span className="text-lg">💡</span>
        </div>
        <div>
          <p className="text-amber-400 text-xs font-bold tracking-widest uppercase">冷知识解锁</p>
        </div>
      </div>

      {/* 分割线 */}
      <div className="mt-4 mb-6 h-px bg-white/10" />

      {/* Hint */}
      <div className="flex-1 flex items-center">
        <p className="text-white/90 text-lg leading-relaxed font-medium">
          {card.hint}
        </p>
      </div>

      {/* 底部 */}
      <div className="flex items-center justify-end">
        <span className="text-white/30 text-xs">← 点击翻回</span>
      </div>
    </div>
  )
}
