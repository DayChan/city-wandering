'use client'

import { Theme, THEME_LABELS, THEME_EMOJIS } from '@/lib/types'
import { useCardStore } from '@/store/useCardStore'

const THEMES: Theme[] = ['random', 'food', 'architecture', 'culture', 'nature', 'color-walk']

const ACTIVE_STYLES: Record<Theme, string> = {
  food: 'bg-orange-500 text-white border-orange-500',
  architecture: 'bg-stone-600 text-white border-stone-600',
  culture: 'bg-blue-500 text-white border-blue-500',
  nature: 'bg-emerald-500 text-white border-emerald-500',
  'color-walk': 'bg-purple-500 text-white border-purple-500',
  random: 'bg-gray-800 text-white border-gray-800',
}

export function ThemeFilter() {
  const { selectedTheme, setSelectedTheme } = useCardStore()

  return (
    <div className="flex flex-wrap gap-2 justify-center max-w-sm">
      {THEMES.map((theme) => {
        const isActive = selectedTheme === theme || (theme === 'random' && !selectedTheme)
        return (
          <button
            key={theme}
            onClick={() => setSelectedTheme(theme === 'random' ? null : theme)}
            className={`
              flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-sm font-medium border transition-all duration-200
              ${isActive
                ? ACTIVE_STYLES[theme]
                : 'bg-white text-gray-500 border-gray-200 hover:border-gray-400 hover:text-gray-700'
              }
            `}
          >
            <span>{THEME_EMOJIS[theme]}</span>
            <span>{THEME_LABELS[theme]}</span>
          </button>
        )
      })}
    </div>
  )
}
