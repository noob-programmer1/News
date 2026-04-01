import Foundation
import Combine

final class MockCommentRepository: CommentRepository {
    private static let sampleComments: [Comment] = [
        Comment(id: UUID(), authorName: "Sarah Chen",
                text: "Great article! Really insightful perspective on this topic.",
                date: Date().addingTimeInterval(-300)),
        Comment(id: UUID(), authorName: "James Wilson",
                text: "I've been following this story closely. The implications are significant for the industry.",
                date: Date().addingTimeInterval(-3600)),
        Comment(id: UUID(), authorName: "Maria Garcia",
                text: "Thanks for sharing. Would love to see a follow-up piece on this.",
                date: Date().addingTimeInterval(-7200)),
        Comment(id: UUID(), authorName: "Alex Thompson",
                text: "Interesting take. I think there are some additional factors worth considering here that the article doesn't cover.",
                date: Date().addingTimeInterval(-14400)),
        Comment(id: UUID(), authorName: "Priya Patel",
                text: "Well written and balanced. Refreshing to see quality journalism like this.",
                date: Date().addingTimeInterval(-86400)),
        Comment(id: UUID(), authorName: "David Kim",
                text: "This is exactly what I was looking for. Shared it with my team.",
                date: Date().addingTimeInterval(-172800)),
        Comment(id: UUID(), authorName: "Emma Roberts",
                text: "The data presented here is compelling. Would be great to see sources linked.",
                date: Date().addingTimeInterval(-259200)),
    ]

    func comments(for articleId: String) -> AnyPublisher<[Comment], Never> {
        let shuffled = Self.sampleComments.shuffled()
        return Just(shuffled)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
