'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'

interface AuthModalProps {
  isOpen: boolean
  onClose: () => void
}

type Tab = 'login' | 'signup'

const ERROR_MAP: Record<string, string> = {
  'Invalid login credentials': '邮箱或密码错误',
  'Email not confirmed': '邮箱尚未验证，请先查收确认邮件',
  'User already registered': '该邮箱已注册，请直接登录',
  'Password should be at least 6 characters': '密码至少需要 6 个字符',
  'Unable to validate email address: invalid format': '邮箱格式不正确',
  'Email rate limit exceeded': '发送频率过高，请稍后再试',
  'signup_disabled': '当前不开放注册',
}

function localizeError(msg: string): string {
  for (const [key, val] of Object.entries(ERROR_MAP)) {
    if (msg.includes(key)) return val
  }
  return msg
}

export function AuthModal({ isOpen, onClose }: AuthModalProps) {
  const [tab, setTab] = useState<Tab>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [info, setInfo] = useState('')
  const [loading, setLoading] = useState(false)
  const { setUser } = useAuthStore()

  function reset() {
    setError('')
    setInfo('')
    setEmail('')
    setPassword('')
    setConfirm('')
  }

  function switchTab(t: Tab) {
    setTab(t)
    setError('')
    setInfo('')
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setInfo('')

    if (password.length < 8) {
      setError('密码至少需要 8 个字符')
      return
    }
    if (tab === 'signup' && password !== confirm) {
      setError('两次输入的密码不一致')
      return
    }

    setLoading(true)
    const supabase = createClient()

    try {
      if (tab === 'login') {
        const { data, error: err } = await supabase.auth.signInWithPassword({ email, password })
        if (err) { setError(localizeError(err.message)); return }
        setUser(data.user)
        reset()
        onClose()
      } else {
        const { error: err } = await supabase.auth.signUp({ email, password })
        if (err) { setError(localizeError(err.message)); return }
        setInfo('注册成功！请查收邮件并点击确认链接后登录。')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* 遮罩 */}
          <motion.div
            key="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/30 backdrop-blur-sm z-40"
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            key="modal"
            initial={{ opacity: 0, scale: 0.96, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 12 }}
            transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
            className="fixed inset-0 z-50 flex items-center justify-center px-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="w-full max-w-sm bg-white rounded-3xl shadow-2xl p-8">
              {/* 标题 */}
              <div className="mb-6">
                <h2 className="text-xl font-bold text-gray-900">欢迎回来</h2>
                <p className="text-sm text-gray-400 mt-1">登录或注册，记录你的城市漫步</p>
              </div>

              {/* Tab */}
              <div className="flex gap-6 mb-6 border-b border-gray-100">
                {(['login', 'signup'] as Tab[]).map((t) => (
                  <button
                    key={t}
                    onClick={() => switchTab(t)}
                    className={`relative pb-3 text-sm font-semibold transition-colors ${
                      tab === t ? 'text-gray-900' : 'text-gray-400 hover:text-gray-600'
                    }`}
                  >
                    {t === 'login' ? '登录' : '注册'}
                    {tab === t && (
                      <motion.div
                        layoutId="tab-underline"
                        className="absolute bottom-0 left-0 right-0 h-0.5 bg-gray-900 rounded-full"
                      />
                    )}
                  </button>
                ))}
              </div>

              {/* 表单 */}
              <form onSubmit={handleSubmit} className="flex flex-col gap-3">
                <input
                  type="email"
                  required
                  placeholder="邮箱地址"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-gray-400 transition-colors bg-gray-50 focus:bg-white"
                />
                <input
                  type="password"
                  required
                  placeholder="密码（至少 8 位）"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-gray-400 transition-colors bg-gray-50 focus:bg-white"
                />
                <AnimatePresence>
                  {tab === 'signup' && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.2 }}
                      style={{ overflow: 'hidden' }}
                    >
                      <input
                        type="password"
                        required={tab === 'signup'}
                        placeholder="确认密码"
                        value={confirm}
                        onChange={(e) => setConfirm(e.target.value)}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-gray-400 transition-colors bg-gray-50 focus:bg-white"
                      />
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* 错误 / 成功提示 */}
                <AnimatePresence mode="wait">
                  {error && (
                    <motion.p
                      key="error"
                      initial={{ opacity: 0, y: -4 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0 }}
                      className="text-red-500 text-xs px-1"
                    >
                      {error}
                    </motion.p>
                  )}
                  {info && (
                    <motion.p
                      key="info"
                      initial={{ opacity: 0, y: -4 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0 }}
                      className="text-green-600 text-xs px-1"
                    >
                      {info}
                    </motion.p>
                  )}
                </AnimatePresence>

                <button
                  type="submit"
                  disabled={loading}
                  className="mt-1 w-full py-3 rounded-[14px] bg-gray-900 text-white text-sm font-semibold hover:bg-gray-700 active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {loading && (
                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  )}
                  {tab === 'login' ? '登录' : '注册'}
                </button>
              </form>

              {/* 关闭 */}
              <button
                onClick={onClose}
                className="absolute top-5 right-5 w-8 h-8 flex items-center justify-center rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
              >
                ✕
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
