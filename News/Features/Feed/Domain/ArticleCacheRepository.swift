import Foundation

protocol ArticleCacheRepository {
    func cacheHTML(_ html: String, for articleUrl: String)
    func cachedHTML(for articleUrl: String) -> String?
}
