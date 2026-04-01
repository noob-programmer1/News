import Foundation

struct Comment: Hashable, Identifiable {
    let id: UUID
    let authorName: String
    let text: String
    let date: Date

    var initials: String {
        let parts = authorName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    var timeAgo: String { date.timeAgo }
}
