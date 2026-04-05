'use client'

import { useEffect } from 'react'
import { useLocationStore } from '@/store/useLocationStore'
import { detectFromIP } from '@/lib/location'

export function LocationProvider({ children }: { children: React.ReactNode }) {
  const { city, source, setDetected, setDetecting } = useLocationStore()

  useEffect(() => {
    // 手动选择过城市，不覆盖
    if (source === 'manual' && city) return
    // 已有城市（本次会话已检测过），跳过
    if (city) return

    async function detect() {
      setDetecting(true)
      try {
        const found = await detectFromIP()
        if (found) setDetected(found.slug, found.label, 'ip')
      } finally {
        setDetecting(false)
      }
    }
    detect()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return <>{children}</>
}
