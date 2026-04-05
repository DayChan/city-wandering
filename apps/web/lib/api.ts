import { Card, CardFilters, ApiResponse } from './types'

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8787'

async function apiFetch<T>(path: string): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    cache: 'no-store',
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(err || `API error: ${res.status}`)
  }
  const json: ApiResponse<T> = await res.json()
  if (json.error) throw new Error(json.error)
  if (json.data === null) throw new Error('No data returned')
  return json.data
}

export const cardApi = {
  getRandom: (filters?: CardFilters) => {
    const params = new URLSearchParams()
    if (filters?.theme && filters.theme !== 'random') params.set('theme', filters.theme)
    if (filters?.city) params.set('city', filters.city)
    if (filters?.difficulty) params.set('difficulty', String(filters.difficulty))
    const qs = params.toString()
    return apiFetch<Card>(`/cards/random${qs ? `?${qs}` : ''}`)
  },

  getList: (filters?: CardFilters) => {
    const params = new URLSearchParams()
    if (filters?.theme) params.set('theme', filters.theme)
    const qs = params.toString()
    return apiFetch<Card[]>(`/cards${qs ? `?${qs}` : ''}`)
  },
}
