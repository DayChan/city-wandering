import type { Metadata } from 'next'
import { Geist } from 'next/font/google'
import { AuthProvider } from '@/components/AuthProvider'
import { LocationProvider } from '@/components/LocationProvider'
import { Header } from '@/components/Header'
import './globals.css'

const geist = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
})

export const metadata: Metadata = {
  title: '陌生城市漫步卡',
  description: '用随机任务卡重新发现城市的隐秘角落',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh" className={`${geist.variable} h-full antialiased`}>
      <body className="min-h-full bg-gray-50 flex flex-col">
        <AuthProvider>
          <LocationProvider>
            <Header />
            {children}
          </LocationProvider>
        </AuthProvider>
      </body>
    </html>
  )
}
