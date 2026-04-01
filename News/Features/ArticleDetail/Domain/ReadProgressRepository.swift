import Foundation

protocol ReadProgressRepository {
    func saveProgress(for articleUrl: String, scrollY: Double, contentHeight: Double)
    func loadProgress(for articleUrl: String) -> (scrollY: Double, contentHeight: Double)?
}
