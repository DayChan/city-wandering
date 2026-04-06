import Foundation

struct CardFilters {
    var theme: Theme?
    var city: String?
    var difficulty: Int?
}

actor CardService {
    static let shared = CardService()

    private let baseURL = URL(string: "https://city-wandering-api.jonaschen.workers.dev")!
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    func getRandom(filters: CardFilters = CardFilters()) async throws -> Card {
        var components = URLComponents(url: baseURL.appendingPathComponent("cards/random"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []
        if let theme = filters.theme, theme != .random {
            queryItems.append(.init(name: "theme", value: theme.rawValue))
        }
        if let city = filters.city {
            queryItems.append(.init(name: "city", value: city))
        }
        if let difficulty = filters.difficulty {
            queryItems.append(.init(name: "difficulty", value: String(difficulty)))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CardError.serverError
        }

        let result = try decoder.decode(ApiResponse<Card>.self, from: data)
        if let error = result.error { throw CardError.apiError(error) }
        guard let card = result.data else { throw CardError.noData }
        return card
    }
}

enum CardError: LocalizedError {
    case serverError
    case noData
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .serverError: return "服务器错误，请稍后重试"
        case .noData: return "没有找到合适的卡片"
        case .apiError(let msg): return msg
        }
    }
}
