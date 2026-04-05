export interface CityDef {
  slug: string
  label: string
  region: 'china' | 'east-asia' | 'north-america'
  lat: number
  lng: number
  ipKeywords: string[] // lowercase, matched against IP API city/region fields
}

export const CITIES: CityDef[] = [
  // 中国
  { slug: 'beijing',     label: '北京', region: 'china',         lat: 39.91,  lng: 116.39,  ipKeywords: ['beijing', 'peking'] },
  { slug: 'shanghai',    label: '上海', region: 'china',         lat: 31.23,  lng: 121.47,  ipKeywords: ['shanghai'] },
  { slug: 'guangzhou',   label: '广州', region: 'china',         lat: 23.13,  lng: 113.26,  ipKeywords: ['guangzhou', 'canton'] },
  { slug: 'shenzhen',    label: '深圳', region: 'china',         lat: 22.54,  lng: 114.06,  ipKeywords: ['shenzhen'] },
  { slug: 'chengdu',     label: '成都', region: 'china',         lat: 30.66,  lng: 104.07,  ipKeywords: ['chengdu'] },
  { slug: 'hangzhou',    label: '杭州', region: 'china',         lat: 30.25,  lng: 120.15,  ipKeywords: ['hangzhou'] },
  { slug: 'wuhan',       label: '武汉', region: 'china',         lat: 30.59,  lng: 114.31,  ipKeywords: ['wuhan'] },
  { slug: 'xian',        label: '西安', region: 'china',         lat: 34.27,  lng: 108.95,  ipKeywords: ["xi'an", 'xian'] },
  // 东亚
  { slug: 'tokyo',       label: '东京', region: 'east-asia',     lat: 35.69,  lng: 139.69,  ipKeywords: ['tokyo'] },
  { slug: 'seoul',       label: '首尔', region: 'east-asia',     lat: 37.57,  lng: 126.98,  ipKeywords: ['seoul'] },
  { slug: 'hongkong',    label: '香港', region: 'east-asia',     lat: 22.32,  lng: 114.17,  ipKeywords: ['hong kong', 'hongkong'] },
  { slug: 'taipei',      label: '台北', region: 'east-asia',     lat: 25.05,  lng: 121.53,  ipKeywords: ['taipei'] },
  // 北美
  { slug: 'new-york',    label: '纽约', region: 'north-america', lat: 40.71,  lng: -74.01,  ipKeywords: ['new york'] },
  { slug: 'los-angeles', label: '洛杉矶', region: 'north-america', lat: 34.05, lng: -118.24, ipKeywords: ['los angeles'] },
  { slug: 'san-francisco', label: '旧金山', region: 'north-america', lat: 37.77, lng: -122.42, ipKeywords: ['san francisco'] },
]

export const REGION_LABELS: Record<CityDef['region'], string> = {
  'china': '🇨🇳 中国',
  'east-asia': '🌏 东亚',
  'north-america': '🌎 北美',
}

export const CITY_MAP = Object.fromEntries(CITIES.map((c) => [c.slug, c]))
