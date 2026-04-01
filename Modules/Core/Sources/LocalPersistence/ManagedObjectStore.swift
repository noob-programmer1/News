import Foundation
@preconcurrency import CoreData

// MARK: - ManagedObjectStore
public final class ManagedObjectStore<Entity: NSManagedObject>: @unchecked Sendable {
    private let context: NSManagedObjectContext
    private let entityName: String

    public init(context: NSManagedObjectContext, entityName: String) {
        self.context = context
        self.entityName = entityName
    }

    public func fetch(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        limit: Int = 0
    ) -> [Entity] {
        var result: [Entity] = []
        context.performAndWait { [context, entityName] in
            let request = NSFetchRequest<Entity>(entityName: entityName)
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            if limit > 0 { request.fetchLimit = limit }
            result = (try? context.fetch(request)) ?? []
        }
        return result
    }

    public func count(predicate: NSPredicate? = nil) -> Int {
        var result = 0
        context.performAndWait { [context, entityName] in
            let request = NSFetchRequest<Entity>(entityName: entityName)
            request.predicate = predicate
            result = (try? context.count(for: request)) ?? 0
        }
        return result
    }

    public func first(predicate: NSPredicate? = nil) -> Entity? {
        fetch(predicate: predicate, limit: 1).first
    }

    @discardableResult
    public func create(_ configure: @Sendable (Entity) -> Void) -> Entity {
        var entity: Entity!
        context.performAndWait { [context] in
            entity = Entity(context: context)
            configure(entity)
        }
        return entity
    }

    public func delete(_ object: Entity) {
        context.performAndWait { [context] in context.delete(object) }
    }

    public func deleteAll(predicate: NSPredicate? = nil) {
        context.performAndWait { [context, entityName] in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.predicate = predicate
            guard let objects = try? context.fetch(request) as? [NSManagedObject] else { return }
            objects.forEach { context.delete($0) }
        }
    }

    public func save() {
        context.performAndWait { [context] in
            guard context.hasChanges else { return }
            do { try context.save() }
            catch {
                print("[ManagedObjectStore] Save failed: \(error)")
                context.rollback()
            }
        }
    }

    @discardableResult
    public func upsert(predicate: NSPredicate, configure: @Sendable (Entity) -> Void) -> Entity {
        var entity: Entity!
        context.performAndWait { [context, entityName] in
            let request = NSFetchRequest<Entity>(entityName: entityName)
            request.predicate = predicate
            request.fetchLimit = 1
            entity = (try? context.fetch(request))?.first ?? Entity(context: context)
            configure(entity)
        }
        return entity
    }
}
