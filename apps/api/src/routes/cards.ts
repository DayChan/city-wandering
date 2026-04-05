import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'
import { createClient } from '@supabase/supabase-js'
import { Redis } from '@upstash/redis/cloudflare'
import type { Env } from '../index'

const themeEnum = z.enum([
  'food',
  'architecture',
  'culture',
  'nature',
  'color-walk',
  'random',
])

const querySchema = z.object({
  theme: themeEnum.optional(),
  city: z.string().optional(),
  difficulty: z.coerce.number().min(1).max(3).optional(),
})

export const cards = new Hono<{ Bindings: Env }>()

// GET /cards/random?theme=food&city=universal
cards.get('/random', zValidator('query', querySchema), async (c) => {
  const { theme, city, difficulty } = c.req.valid('query')

  const redis = new Redis({
    url: c.env.UPSTASH_REDIS_REST_URL,
    token: c.env.UPSTASH_REDIS_REST_TOKEN,
  })

  const cacheKey = `cards:ids:${theme ?? 'all'}:${city ?? 'all'}:${difficulty ?? 'all'}`

  let cardIds: string[] | null = await redis.get(cacheKey)

  const supabase = createClient(c.env.SUPABASE_URL, c.env.SUPABASE_SERVICE_ROLE_KEY)

  if (!cardIds || cardIds.length === 0) {
    let query = supabase.from('cards').select('id').eq('is_active', true)
    if (theme && theme !== 'random') query = query.eq('theme', theme)
    if (city) query = query.or(`city.eq.${city},city.eq.universal`)
    if (difficulty) query = query.eq('difficulty', difficulty)

    const { data, error } = await query
    if (error) return c.json({ data: null, error: error.message }, 500)
    if (!data || data.length === 0) return c.json({ data: null, error: 'No cards found' }, 404)

    cardIds = data.map((r) => r.id)
    await redis.set(cacheKey, JSON.stringify(cardIds), { ex: 1800 })
  }

  const randomId = cardIds[Math.floor(Math.random() * cardIds.length)]

  const { data: card, error } = await supabase
    .from('cards')
    .select('*')
    .eq('id', randomId)
    .single()

  if (error || !card) return c.json({ data: null, error: 'Card not found' }, 404)

  return c.json({ data: card })
})

// GET /cards?theme=food
cards.get('/', zValidator('query', querySchema), async (c) => {
  const { theme, city, difficulty } = c.req.valid('query')

  const supabase = createClient(c.env.SUPABASE_URL, c.env.SUPABASE_SERVICE_ROLE_KEY)

  let query = supabase
    .from('cards')
    .select('*')
    .eq('is_active', true)
    .order('created_at', { ascending: false })

  if (theme && theme !== 'random') query = query.eq('theme', theme)
  if (city) query = query.or(`city.eq.${city},city.eq.universal`)
  if (difficulty) query = query.eq('difficulty', difficulty)

  const { data, error } = await query
  if (error) return c.json({ data: null, error: error.message }, 500)

  return c.json({ data: data ?? [] })
})
