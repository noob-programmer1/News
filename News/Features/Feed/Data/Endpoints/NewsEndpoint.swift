import Foundation
import Networking

private var gNewsAPIKey: String {
    Bundle.main.object(forInfoDictionaryKey: "GNEWS_API_KEY") as? String ?? ""
}

enum NewsEndpoint: Endpoint {
    case topHeadlines(category: String = "general", page: Int = 1, max: Int = 10)
    case search(query: String, page: Int = 1, max: Int = 10)

    var path: String {
        switch self {
        case .topHeadlines: "/api/v4/top-headlines"
        case .search: "/api/v4/search"
        }
    }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "apikey", value: gNewsAPIKey),
        ]

        switch self {
        case .topHeadlines(let category, let page, let max):
            items.append(contentsOf: [
                URLQueryItem(name: "category", value: category),
                URLQueryItem(name: "max", value: "\(max)"),
                URLQueryItem(name: "page", value: "\(page)"),
            ])
        case .search(let query, let page, let max):
            items.append(contentsOf: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "max", value: "\(max)"),
                URLQueryItem(name: "page", value: "\(page)"),
            ])
        }

        return items
    }
}
