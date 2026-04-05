'use client'

import { useState, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { createClient } from '@/lib/supabase/browser'
import { useAuthStore } from '@/store/useAuthStore'
import { computeEarnedBadges } from '@/lib/badges'
import { BadgeUnlockToast } from './BadgeUnlockToast'
import type { Card, Theme } from '@/lib/types'

interface CheckInModalProps {
  isOpen: boolean
  onClose: () => void
  card: Card
}

export function CheckInModal({ isOpen, onClose, card }: CheckInModalProps) {
  const { user } = useAuthStore()
  const [photo, setPhoto] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [note, setNote] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)
  const [error, setError] = useState('')
  const [newBadges, setNewBadges] = useState<string[]>([])
  const inputRef = useRef<HTMLInputElement>(null)

  const handleFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) {
      setError('请上传图片文件')
      return
    }
    if (file.size > 10 * 1024 * 1024) {
      setError('图片不能超过 10MB')
      return
    }
    setError('')
    setPhoto(file)
    setPreview(URL.createObjectURL(file))
  }, [])

  function handleDrop(e: React.DragEvent) {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (file) handleFile(file)
  }

  function handleClose() {
    setPhoto(null)
    setPreview(null)
    setNote('')
    setError('')
    setDone(false)
    onClose()
  }

  async function checkAndAwardBadges(supabase: ReturnType<typeof createClient>) {
    if (!user) return

    // 查询该用户所有打卡记录（含关联卡片的 theme）
    const { data: checkIns } = await supabase
      .from('check_ins')
      .select('card_id, cards(theme)')
      .eq('user_id', user.id)

    if (!checkIns) return

    const totalCount = checkIns.length
    const themeCounts: Partial<Record<Theme, number>> = {}
    for (const ci of checkIns) {
      const theme = (ci.cards as unknown as { theme: Theme } | null)?.theme
      if (theme) themeCounts[theme] = (themeCounts[theme] ?? 0) + 1
    }

    const shouldHave = computeEarnedBadges({ totalCount, themeCounts })

    // 查询已有徽章
    const { data: existing } = await supabase
      .from('user_badges')
      .select('badge_id')
      .eq('user_id', user.id)

    const existingSet = new Set((existing ?? []).map((r) => r.badge_id))
    const toAward = shouldHave.filter((id) => !existingSet.has(id))

    if (toAward.length === 0) return

    await supabase.from('user_badges').insert(
      toAward.map((badge_id) => ({ user_id: user.id, badge_id }))
    )
    setNewBadges(toAward)
  }

  async function handleSubmit() {
    if (!user) return
    setLoading(true)
    setError('')

    try {
      const supabase = createClient()
      let photoUrl: string | null = null

      // 上传图片到 Supabase Storage
      if (photo) {
        const ext = photo.name.split('.').pop() ?? 'jpg'
        const path = `${user.id}/${Date.now()}.${ext}`
        const { error: uploadErr } = await supabase.storage
          .from('check-in-photos')
          .upload(path, photo, { upsert: false })
        if (uploadErr) throw new Error(uploadErr.message)

        const { data: { publicUrl } } = supabase.storage
          .from('check-in-photos')
          .getPublicUrl(path)
        photoUrl = publicUrl
      }

      // 保存打卡记录
      const { error: insertErr } = await supabase.from('check_ins').insert({
        user_id: user.id,
        card_id: card.id,
        photo_url: photoUrl,
        note: note.trim() || null,
      })
      if (insertErr) throw new Error(insertErr.message)

      // 检测新解锁的徽章
      await checkAndAwardBadges(supabase)

      // 推送社区通知（fire-and-forget，失败不影响打卡）
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.access_token) {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL
        if (apiUrl) {
          fetch(`${apiUrl}/push/notify`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({
              title: '社区有新打卡 🗺️',
              body: `有人完成了「${card.title.slice(0, 20)}」`,
              url: '/log',
            }),
          }).catch(() => {})
        }
      }

      setDone(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : '打卡失败，请重试')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            key="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/30 backdrop-blur-sm z-40"
            onClick={handleClose}
          />

          <motion.div
            key="modal"
            initial={{ opacity: 0, scale: 0.96, y: 12 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 12 }}
            transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
            className="fixed inset-0 z-50 flex items-center justify-center px-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="relative w-full max-w-sm bg-white rounded-3xl shadow-2xl p-7">
              {/* 关闭 */}
              <button
                onClick={handleClose}
                className="absolute top-5 right-5 w-8 h-8 flex items-center justify-center rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
              >✕</button>

              {done ? (
                // 成功状态
                <motion.div
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex flex-col items-center gap-4 py-6 text-center"
                >
                  <div className="text-5xl">🎉</div>
                  <div>
                    <p className="font-bold text-gray-900 text-lg">打卡成功！</p>
                    <p className="text-gray-400 text-sm mt-1">任务「{card.title.slice(0, 16)}…」已完成</p>
                  </div>
                  <button
                    onClick={handleClose}
                    className="mt-2 px-8 py-3 bg-gray-900 text-white text-sm font-semibold rounded-2xl hover:bg-gray-700 active:scale-95 transition-all"
                  >
                    继续漫步
                  </button>
                </motion.div>
              ) : (
                <>
                  <h2 className="text-lg font-bold text-gray-900 mb-1">打卡记录</h2>
                  <p className="text-xs text-gray-400 mb-5 leading-relaxed line-clamp-2">{card.title}</p>

                  {/* 图片上传区域 */}
                  <div
                    className={`relative rounded-2xl border-2 border-dashed transition-all cursor-pointer overflow-hidden mb-4 ${
                      preview ? 'border-transparent' : 'border-gray-200 hover:border-gray-400'
                    }`}
                    style={{ height: 180 }}
                    onDrop={handleDrop}
                    onDragOver={(e) => e.preventDefault()}
                    onClick={() => inputRef.current?.click()}
                  >
                    {preview ? (
                      <>
                        <img src={preview} alt="预览" className="w-full h-full object-cover" />
                        <button
                          onClick={(e) => { e.stopPropagation(); setPhoto(null); setPreview(null) }}
                          className="absolute top-2 right-2 w-7 h-7 bg-black/50 text-white text-xs rounded-full flex items-center justify-center hover:bg-black/70"
                        >✕</button>
                      </>
                    ) : (
                      <div className="flex flex-col items-center justify-center h-full gap-2 text-gray-300">
                        <span className="text-3xl">📷</span>
                        <span className="text-xs">点击或拖拽上传照片（可选）</span>
                      </div>
                    )}
                  </div>
                  <input
                    ref={inputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => { const f = e.target.files?.[0]; if (f) handleFile(f) }}
                  />

                  {/* 备注 */}
                  <textarea
                    placeholder="写点什么……（可选）"
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    maxLength={200}
                    rows={2}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-gray-400 transition-colors bg-gray-50 focus:bg-white resize-none mb-4"
                  />

                  <AnimatePresence>
                    {error && (
                      <motion.p
                        initial={{ opacity: 0, y: -4 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0 }}
                        className="text-red-500 text-xs mb-3"
                      >{error}</motion.p>
                    )}
                  </AnimatePresence>

                  <button
                    onClick={handleSubmit}
                    disabled={loading}
                    className="w-full py-3 bg-gray-900 text-white text-sm font-semibold rounded-2xl hover:bg-gray-700 active:scale-95 transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    {loading && <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />}
                    完成打卡
                  </button>
                </>
              )}

              <BadgeUnlockToast
                badgeIds={newBadges}
                onDismiss={() => setNewBadges([])}
              />
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
