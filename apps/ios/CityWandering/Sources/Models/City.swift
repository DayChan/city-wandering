import Foundation
import CoreLocation

struct CityDef: Identifiable {
    var id: String { slug }
    let slug: String
    let label: String
    let region: Region
    let coordinate: CLLocationCoordinate2D
    let ipKeywords: [String]

    enum Region: String {
        case china = "china"
        case eastAsia = "east-asia"
        case northAmerica = "north-america"

        var label: String {
            switch self {
            case .china: return "🇨🇳 中国"
            case .eastAsia: return "🌏 东亚"
            case .northAmerica: return "🌎 北美"
            }
        }
    }
}

let allCities: [CityDef] = [
    // 中国
    CityDef(slug: "beijing",       label: "北京",   region: .china,        coordinate: .init(latitude: 39.91, longitude: 116.39), ipKeywords: ["beijing", "peking"]),
    CityDef(slug: "shanghai",      label: "上海",   region: .china,        coordinate: .init(latitude: 31.23, longitude: 121.47), ipKeywords: ["shanghai"]),
    CityDef(slug: "guangzhou",     label: "广州",   region: .china,        coordinate: .init(latitude: 23.13, longitude: 113.26), ipKeywords: ["guangzhou", "canton"]),
    CityDef(slug: "shenzhen",      label: "深圳",   region: .china,        coordinate: .init(latitude: 22.54, longitude: 114.06), ipKeywords: ["shenzhen"]),
    CityDef(slug: "chengdu",       label: "成都",   region: .china,        coordinate: .init(latitude: 30.66, longitude: 104.07), ipKeywords: ["chengdu"]),
    CityDef(slug: "hangzhou",      label: "杭州",   region: .china,        coordinate: .init(latitude: 30.25, longitude: 120.15), ipKeywords: ["hangzhou"]),
    CityDef(slug: "wuhan",         label: "武汉",   region: .china,        coordinate: .init(latitude: 30.59, longitude: 114.31), ipKeywords: ["wuhan"]),
    CityDef(slug: "xian",          label: "西安",   region: .china,        coordinate: .init(latitude: 34.27, longitude: 108.95), ipKeywords: ["xi'an", "xian"]),
    // 东亚
    CityDef(slug: "tokyo",         label: "东京",   region: .eastAsia,     coordinate: .init(latitude: 35.69, longitude: 139.69), ipKeywords: ["tokyo"]),
    CityDef(slug: "seoul",         label: "首尔",   region: .eastAsia,     coordinate: .init(latitude: 37.57, longitude: 126.98), ipKeywords: ["seoul"]),
    CityDef(slug: "hongkong",      label: "香港",   region: .eastAsia,     coordinate: .init(latitude: 22.32, longitude: 114.17), ipKeywords: ["hong kong", "hongkong"]),
    CityDef(slug: "taipei",        label: "台北",   region: .eastAsia,     coordinate: .init(latitude: 25.05, longitude: 121.53), ipKeywords: ["taipei"]),
    // 北美
    CityDef(slug: "new-york",      label: "纽约",   region: .northAmerica, coordinate: .init(latitude: 40.71, longitude: -74.01), ipKeywords: ["new york"]),
    CityDef(slug: "los-angeles",   label: "洛杉矶", region: .northAmerica, coordinate: .init(latitude: 34.05, longitude: -118.24), ipKeywords: ["los angeles"]),
    CityDef(slug: "san-francisco", label: "旧金山", region: .northAmerica, coordinate: .init(latitude: 37.77, longitude: -122.42), ipKeywords: ["san francisco"]),
]

func findNearestCity(to coordinate: CLLocationCoordinate2D, maxKm: Double = 300) -> CityDef? {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    var nearest: CityDef?
    var minDist = Double.infinity
    for city in allCities {
        let cityLocation = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
        let dist = location.distance(from: cityLocation) / 1000
        if dist < minDist { minDist = dist; nearest = city }
    }
    return minDist <= maxKm ? nearest : nil
}

func matchCityFromIP(_ ipCity: String) -> CityDef? {
    let q = ipCity.lowercased()
    return allCities.first { city in
        city.ipKeywords.contains { k in q.contains(k) || k.contains(q) }
    }
}
