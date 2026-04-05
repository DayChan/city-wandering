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
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ApiResponse<T> {
  data: T | null
  error?: string
}
