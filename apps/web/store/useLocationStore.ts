import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export type LocationSource = 'gps' | 'ip' | 'manual'

interface LocationState {
  city: string | null       // city slug (e.g. 'shanghai')
  cityLabel: string | null  // display name (e.g. '上海')
  source: LocationSource | null
  isDetecting: boolean

  setManualCity: (slug: string, label: string) => void
  setDetected: (slug: string | null, label: string, source: 'gps' | 'ip') => void
  setDetecting: (v: boolean) => void
  reset: () => void         // clear manual selection, re-trigger auto detect
}

export const useLocationStore = create<LocationState>()(
  persist(
    (set) => ({
      city: null,
      cityLabel: null,
      source: null,
      isDetecting: false,

      setManualCity: (slug, label) =>
        set({ city: slug, cityLabel: label, source: 'manual' }),

      setDetected: (slug, label, source) =>
        set({ city: slug, cityLabel: label, source }),

      setDetecting: (v) => set({ isDetecting: v }),

      reset: () => set({ city: null, cityLabel: null, source: null }),
    }),
    {
      name: 'city-wandering-location',
      // 只持久化手动选择，自动检测结果每次重新获取
      partialize: (state) =>
        state.source === 'manual'
          ? { city: state.city, cityLabel: state.cityLabel, source: state.source }
          : {},
    }
  )
)
