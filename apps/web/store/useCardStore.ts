import { create } from 'zustand'
import { Card, Theme } from '@/lib/types'

interface CardStore {
  currentCard: Card | null
  selectedTheme: Theme | null
  isFlipped: boolean
  isLoading: boolean
  error: string | null

  setCurrentCard: (card: Card | null) => void
  setSelectedTheme: (theme: Theme | null) => void
  setIsFlipped: (flipped: boolean) => void
  setIsLoading: (loading: boolean) => void
  setError: (error: string | null) => void
}

export const useCardStore = create<CardStore>((set) => ({
  currentCard: null,
  selectedTheme: null,
  isFlipped: false,
  isLoading: false,
  error: null,

  setCurrentCard: (card) => set({ currentCard: card, isFlipped: false, error: null }),
  setSelectedTheme: (theme) => set({ selectedTheme: theme }),
  setIsFlipped: (flipped) => set({ isFlipped: flipped }),
  setIsLoading: (loading) => set({ isLoading: loading }),
  setError: (error) => set({ error }),
}))
