'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { CITIES, REGION_LABELS, type CityDef } from '@/lib/cities'
import { detectFromGPS, detectFromIP } from '@/lib/location'
import { useLocationStore } from '@/store/useLocationStore'

type GPSStatus = 'idle' | 'requesting' | 'no-permission' | 'no-city' | 'ok'

interface CitySelectorProps {
  isOpen: boolean
  onClose: () => void
}

const REGIONS = ['china', 'east-asia', 'north-america'] as const

const SOURCE_LABEL: Record<string, string> = {
  gps: 'GPS 定位',
  ip: 'IP 推断',
  manual: '手动选择',
}

export function CitySelector({ isOpen, onClose }: CitySelectorProps) {
  const { city: currentCity, cityLabel: currentCityLabel, source, setManualCity, setDetected, setDetecting, reset } = useLocationStore()
  const [query, setQuery] = useState('')
  const [detecting, setLocalDetecting] = useState(false)
  const [gpsStatus, setGpsStatus] = useState<GPSStatus>('idle')

  const filtered = query.trim()
    ? CITIES.filter((c) => c.label.includes(query) || c.slug.includes(query.toLowerCase()))
    : null

  function select(c: CityDef) {
    setManualCity(c.slug, c.label)
    onClose()
  }

  async function handleGPS() {
    setGpsStatus('requesting')
    setLocalDetecting(true)
    setDetecting(true)
    try {
      const result = await detectFromGPS()
      if (result) {
        // 有结果：无论是否在支持城市范围内都展示
        const label = result.label ?? result.supported?.label ?? '未知位置'
        setDetected(result.supported?.slug ?? null, label, 'gps')
        setGpsStatus('ok')
        onClose()
      } else {
        // GPS 失败（权限拒绝或超时）
        const permDenied = await navigator.permissions
          ?.query({ name: 'geolocation' })
          .then((r) => r.state === 'denied')
          .catch(() => false) ?? false
        setGpsStatus(permDenied ? 'no-permission' : 'no-city')
      }
    } finally {
      setLocalDetecting(false)
      setDetecting(false)
    }
  }

  async function handleAutoIP() {
    setLocalDetecting(true)
    setDetecting(true)
    reset()
    try {
      const found = await detectFromIP()
      if (found) setDetected(found.slug, found.label, 'ip')
    } finally {
      setLocalDetecting(false)
      setDetecting(false)
    }
    onClose()
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
            className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40"
            onClick={onClose}
          />
          <motion.div
            key="panel"
            initial={{ opacity: 0, scale: 0.96, y: 8 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 8 }}
            transition={{ duration: 0.2, ease: [0.4, 0, 0.2, 1] }}
            className="fixed inset-0 z-50 flex items-center justify-center px-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="w-full max-w-sm bg-white rounded-3xl shadow-2xl overflow-hidden">
              {/* 标题栏 */}
              <div className="flex items-center justify-between px-5 pt-5 pb-3">
                <h2 className="text-base font-bold text-gray-900">选择城市</h2>
                <button
                  onClick={onClose}
                  className="w-7 h-7 flex items-center justify-center rounded-full text-gray-400 hover:bg-gray-100 transition-all"
                >✕</button>
              </div>

              {/* 当前城市状态 */}
              {currentCityLabel ? (
                <div className="mx-5 mb-3 flex items-center justify-between px-3 py-2.5 bg-gray-50 rounded-xl">
                  <div className="flex items-center gap-2">
                    <span className="text-sm">📍</span>
                    <div>
                      <span className="text-sm font-semibold text-gray-900">{currentCityLabel}</span>
                      {source && (
                        <span className="ml-2 text-xs text-gray-400">{SOURCE_LABEL[source]}</span>
                      )}
                    </div>
                  </div>
                  <button
                    onClick={() => { reset(); onClose() }}
                    className="text-xs text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    清除
                  </button>
                </div>
              ) : (
                <div className="mx-5 mb-3 px-3 py-2.5 bg-amber-50 rounded-xl">
                  <p className="text-xs text-amber-600">📡 未检测到城市，请手动选择或点击自动检测</p>
                </div>
              )}

              {/* 搜索框 */}
              <div className="px-5 pb-3">
                <input
                  type="text"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="搜索城市…"
                  className="w-full px-4 py-2.5 rounded-xl border border-gray-200 text-sm outline-none focus:border-gray-400 bg-gray-50 focus:bg-white transition-colors"
                  autoFocus
                />
              </div>

              {/* 自动检测选项 */}
              {!query && (
                <div className="px-5 pb-2">
                  <div className="flex gap-2">
                    <button
                      onClick={handleGPS}
                      disabled={detecting}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 text-xs font-medium text-gray-600 bg-gray-50 hover:bg-gray-100 rounded-xl transition-all disabled:opacity-50"
                    >
                      {gpsStatus === 'requesting'
                        ? <span className="w-3 h-3 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />
                        : '📡'}
                      GPS 定位
                    </button>
                    <button
                      onClick={handleAutoIP}
                      disabled={detecting}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 text-xs font-medium text-gray-600 bg-gray-50 hover:bg-gray-100 rounded-xl transition-all disabled:opacity-50"
                    >
                      🌐 IP 自动检测
                    </button>
                  </div>
                  {gpsStatus === 'no-permission' && (
                    <p className="text-xs text-amber-600 mt-2 text-center">请在浏览器设置中允许位置权限后重试</p>
                  )}
                  {gpsStatus === 'no-city' && (
                    <p className="text-xs text-gray-400 mt-2 text-center">当前位置暂无支持的城市，请手动选择</p>
                  )}
                </div>
              )}

              {/* 城市列表 */}
              <div className="overflow-y-auto max-h-72 px-5 pb-5">
                {filtered ? (
                  <div className="flex flex-wrap gap-2 pt-1">
                    {filtered.length === 0 ? (
                      <p className="text-xs text-gray-300 py-4 w-full text-center">没有找到「{query}」</p>
                    ) : (
                      filtered.map((c) => (
                        <CityChip key={c.slug} city={c} selected={c.slug === currentCity} onSelect={select} />
                      ))
                    )}
                  </div>
                ) : (
                  REGIONS.map((region) => (
                    <div key={region} className="mb-4">
                      <p className="text-xs text-gray-400 font-medium mb-2">{REGION_LABELS[region]}</p>
                      <div className="flex flex-wrap gap-2">
                        {CITIES.filter((c) => c.region === region).map((c) => (
                          <CityChip key={c.slug} city={c} selected={c.slug === currentCity} onSelect={select} />
                        ))}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

function CityChip({ city, selected, onSelect }: { city: CityDef; selected: boolean; onSelect: (c: CityDef) => void }) {
  return (
    <button
      onClick={() => onSelect(city)}
      className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-all ${
        selected
          ? 'bg-gray-900 text-white'
          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
      }`}
    >
      {city.label}
      {selected && ' ✓'}
    </button>
  )
}
