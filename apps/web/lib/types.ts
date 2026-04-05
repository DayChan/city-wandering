export type Theme =
  | 'food'
  | 'architecture'
  | 'culture'
  | 'nature'
  | 'color-walk'
  | 'random'

export type Difficulty = 1 | 2 | 3

export interface Card {
  id: string
  title: string
  difficulty: Difficulty
  theme: Theme
  city: string
  hint: string
  created_at?: string
}

export interface CardFilters {
  theme?: Theme
  city?: string
  difficulty?: Difficulty
}

export interface ApiResponse<T> {
  data: T | null
  error?: string
}

export const THEME_LABELS: Record<Theme, string> = {
  food: '美食',
  architecture: '建筑',
  culture: '人文',
  nature: '自然',
  'color-walk': 'Color Walk',
  random: '随机',
}

export const DIFFICULTY_LABELS: Record<Difficulty, string> = {
  1: '☆',
  2: '☆☆',
  3: '☆☆☆',
}

export const THEME_COLORS: Record<Theme, string> = {
  food: 'bg-orange-100 text-orange-700 border-orange-200',
  architecture: 'bg-stone-100 text-stone-700 border-stone-200',
  culture: 'bg-blue-100 text-blue-700 border-blue-200',
  nature: 'bg-green-100 text-green-700 border-green-200',
  'color-walk': 'bg-purple-100 text-purple-700 border-purple-200',
  random: 'bg-gray-100 text-gray-700 border-gray-200',
}

export const THEME_EMOJIS: Record<Theme, string> = {
  food: '🍜',
  architecture: '🏛️',
  culture: '🧭',
  nature: '🌿',
  'color-walk': '🎨',
  random: '🎲',
}

// 卡片正面渐变背景
export const THEME_GRADIENTS: Record<Theme, string> = {
  food: 'from-orange-400 via-red-400 to-rose-500',
  architecture: 'from-slate-500 via-stone-500 to-zinc-600',
  culture: 'from-blue-500 via-indigo-500 to-violet-600',
  nature: 'from-green-400 via-emerald-500 to-teal-600',
  'color-walk': 'from-purple-400 via-fuchsia-500 to-pink-500',
  random: 'from-gray-500 via-neutral-500 to-stone-600',
}
