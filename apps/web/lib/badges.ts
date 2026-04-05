import type { Theme } from './types'

export interface BadgeDef {
  id: string
  name: string
  desc: string
  emoji: string
  color: string // Tailwind bg class
}

// 所有徽章定义
export const BADGES: BadgeDef[] = [
  // 主题徽章 — 每个主题首次打卡解锁
  { id: 'theme-food',         name: '美食探险家', desc: '完成第一次美食主题打卡',       emoji: '🍜', color: 'bg-orange-100' },
  { id: 'theme-architecture', name: '城市观察者', desc: '完成第一次建筑主题打卡',       emoji: '🏛️', color: 'bg-stone-100'  },
  { id: 'theme-culture',      name: '人文漫游者', desc: '完成第一次人文主题打卡',       emoji: '🧭', color: 'bg-blue-100'   },
  { id: 'theme-nature',       name: '自然感知者', desc: '完成第一次自然主题打卡',       emoji: '🌿', color: 'bg-green-100'  },
  { id: 'theme-color-walk',   name: 'Color Walker', desc: '完成第一次 Color Walk 打卡', emoji: '🎨', color: 'bg-purple-100' },
  { id: 'theme-random',       name: '随机漫步者', desc: '完成第一次随机主题打卡',       emoji: '🎲', color: 'bg-gray-100'   },
  // 里程碑徽章
  { id: 'milestone-1',  name: '初次出发',   desc: '完成第 1 次打卡',  emoji: '🚶', color: 'bg-sky-100'    },
  { id: 'milestone-5',  name: '漫步常客',   desc: '累计完成 5 次打卡', emoji: '🗺️', color: 'bg-amber-100'  },
  { id: 'milestone-10', name: '城市解密者', desc: '累计完成 10 次打卡', emoji: '🏙️', color: 'bg-rose-100'   },
]

export const BADGE_MAP = Object.fromEntries(BADGES.map((b) => [b.id, b]))

// 根据当前打卡数据计算应解锁哪些徽章（返回 badge_id 列表）
export function computeEarnedBadges(params: {
  totalCount: number
  themeCounts: Partial<Record<Theme, number>>
}): string[] {
  const earned: string[] = []
  const { totalCount, themeCounts } = params

  // 主题徽章
  const themeMap: Record<string, Theme> = {
    'theme-food': 'food',
    'theme-architecture': 'architecture',
    'theme-culture': 'culture',
    'theme-nature': 'nature',
    'theme-color-walk': 'color-walk',
    'theme-random': 'random',
  }
  for (const [badgeId, theme] of Object.entries(themeMap)) {
    if ((themeCounts[theme] ?? 0) >= 1) earned.push(badgeId)
  }

  // 里程碑徽章
  if (totalCount >= 1)  earned.push('milestone-1')
  if (totalCount >= 5)  earned.push('milestone-5')
  if (totalCount >= 10) earned.push('milestone-10')

  return earned
}
