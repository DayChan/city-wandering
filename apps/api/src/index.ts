import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { cards } from './routes/cards'

export type Env = {
  SUPABASE_URL: string
  SUPABASE_SERVICE_ROLE_KEY: string
  UPSTASH_REDIS_REST_URL: string
  UPSTASH_REDIS_REST_TOKEN: string
}

const app = new Hono<{ Bindings: Env }>()

app.use('*', logger())
app.use(
  '*',
  cors({
    origin: [
      'http://localhost:3000',
      'https://city-wandering.vercel.app',
    ],
  })
)

app.get('/health', (c) => c.json({ status: 'ok' }))

app.route('/cards', cards)

export default app
