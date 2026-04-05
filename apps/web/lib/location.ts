import { CITIES, type CityDef } from './cities'

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

/** 找最近的支持城市，超过 maxKm 则返回 null */
export function findNearestCity(lat: number, lng: number, maxKm = 150): CityDef | null {
  let nearest: CityDef | null = null
  let minDist = Infinity
  for (const city of CITIES) {
    const d = haversineKm(lat, lng, city.lat, city.lng)
    if (d < minDist) { minDist = d; nearest = city }
  }
  return minDist <= maxKm ? nearest : null
}

/** 通过 IP API 城市名关键词匹配 */
export function matchCityFromIP(ipCity: string): CityDef | null {
  const q = ipCity.toLowerCase()
  return CITIES.find((c) => c.ipKeywords.some((k) => q.includes(k) || k.includes(q))) ?? null
}

/** 通过 ipinfo.io 静默检测城市（无需授权） */
export async function detectFromIP(): Promise<CityDef | null> {
  try {
    const res = await fetch('https://ipinfo.io/json', {
      signal: AbortSignal.timeout(5000),
    })
    if (!res.ok) return null
    const data: { city?: string; loc?: string } = await res.json()

    // 先尝试城市名关键词匹配
    if (data.city) {
      const matched = matchCityFromIP(data.city)
      if (matched) return matched
    }

    // 再尝试坐标最近邻匹配
    if (data.loc) {
      const [lat, lng] = data.loc.split(',').map(Number)
      return findNearestCity(lat, lng)
    }
    return null
  } catch {
    return null
  }
}

/** 通过浏览器 GPS 定位（需用户授权） */
export function detectFromGPS(): Promise<CityDef | null> {
  return new Promise((resolve) => {
    if (typeof navigator === 'undefined' || !navigator.geolocation) {
      resolve(null)
      return
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => resolve(findNearestCity(pos.coords.latitude, pos.coords.longitude)),
      () => resolve(null),
      { timeout: 8000, maximumAge: 60000 }
    )
  })
}
