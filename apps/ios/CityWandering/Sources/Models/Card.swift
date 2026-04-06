import Foundation

enum Theme: String, Codable, CaseIterable {
    case food = "food"
    case architecture = "architecture"
    case culture = "culture"
    case nature = "nature"
    case colorWalk = "color-walk"
    case random = "random"

    var label: String {
        switch self {
        case .food: return "美食"
        case .architecture: return "建筑"
        case .culture: return "人文"
        case .nature: return "自然"
        case .colorWalk: return "Color Walk"
        case .random: return "随机"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🍜"
        case .architecture: return "🏛️"
        case .culture: return "🎭"
        case .nature: return "🌿"
        case .colorWalk: return "🎨"
        case .random: return "🎲"
        }
    }
}

struct Card: Codable, Identifiable {
    let id: String
    let title: String
    let difficulty: Int
    let theme: Theme
    let city: String
    let hint: String
    let isActive: Bool
    let createdAt: String

    var isUniversal: Bool { city == "universal" }

    var difficultyStars: String {
        String(repeating: "★", count: difficulty) +
        String(repeating: "☆", count: 3 - difficulty)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, difficulty, theme, city, hint
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct ApiResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
}
