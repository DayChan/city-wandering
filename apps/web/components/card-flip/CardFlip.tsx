'use client'

import { motion } from 'framer-motion'
import { useCardStore } from '@/store/useCardStore'
import { CardFront } from './CardFront'
import { CardBack } from './CardBack'

export function CardFlip() {
  const { currentCard, isFlipped, setIsFlipped } = useCardStore()

  if (!currentCard) return null

  return (
    <div
      className="relative w-[320px] h-[480px] cursor-pointer select-none"
      style={{ perspective: '1200px' }}
      onClick={() => setIsFlipped(!isFlipped)}
    >
      <motion.div
        className="relative w-full h-full"
        style={{ transformStyle: 'preserve-3d' }}
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.55, ease: [0.4, 0, 0.2, 1] }}
      >
        <div className="absolute inset-0" style={{ backfaceVisibility: 'hidden' }}>
          <CardFront card={currentCard} />
        </div>
        <div
          className="absolute inset-0"
          style={{ backfaceVisibility: 'hidden', transform: 'rotateY(180deg)' }}
        >
          <CardBack card={currentCard} />
        </div>
      </motion.div>
    </div>
  )
}
