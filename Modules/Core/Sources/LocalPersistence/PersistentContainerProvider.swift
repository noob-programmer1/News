import Foundation
import CoreData


public final class PersistentContainerProvider: @unchecked Sendable {
    public let container: NSPersistentContainer
    public private(set) var loadError: Error?

    public init(name: String, inMemory: Bool = false, model: NSManagedObjectModel? = nil) {
        if let model {
            container = NSPersistentContainer(name: name, managedObjectModel: model)
        } else {
            container = NSPersistentContainer(name: name)
        }

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                print("[PersistentContainerProvider] Failed to load store: \(error)")
                self?.loadError = error
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
