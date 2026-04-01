import Foundation

struct Article: Hashable, Sendable {
    let id: String?
    let title: String
    let description: String?
    let content: String?
    let url: String
    let image: String?
    let publishedAt: String?
    let sourceName: String

    var publishedDate: Date? {
        guard let publishedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: publishedAt) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: publishedAt)
    }

    var stableId: String {
        id ?? url
    }
}
