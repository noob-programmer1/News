import Foundation
import Combine

protocol CommentRepository {
    func comments(for articleId: String) -> AnyPublisher<[Comment], Never>
}
