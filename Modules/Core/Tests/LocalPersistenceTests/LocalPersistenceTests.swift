import Testing
import Foundation
import CoreData
@testable import LocalPersistence

// MARK: - Test Entity

@objc(TestItem)
private final class TestItem: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var value: Int32
}

private func makeModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    let entity = NSEntityDescription()
    entity.name = "TestItem"
    entity.managedObjectClassName = NSStringFromClass(TestItem.self)

    let nameAttr = NSAttributeDescription()
    nameAttr.name = "name"
    nameAttr.attributeType = .stringAttributeType

    let valueAttr = NSAttributeDescription()
    valueAttr.name = "value"
    valueAttr.attributeType = .integer32AttributeType

    entity.properties = [nameAttr, valueAttr]
    model.entities = [entity]
    return model
}

private func makeStore() -> ManagedObjectStore<TestItem> {
    let provider = PersistentContainerProvider(name: "Test", inMemory: true, model: makeModel())
    return ManagedObjectStore(context: provider.viewContext, entityName: "TestItem")
}

// MARK: - PersistentContainerProvider Tests

@Suite("PersistentContainerProvider")
struct PersistentContainerProviderTests {
    @Test("In-memory store loads successfully")
    func inMemoryLoad() {
        let provider = PersistentContainerProvider(name: "Test", inMemory: true, model: makeModel())
        #expect(provider.loadError == nil)
        #expect(provider.viewContext != nil)
    }

    @Test("Provides background context")
    func backgroundContext() {
        let provider = PersistentContainerProvider(name: "Test", inMemory: true, model: makeModel())
        let bg = provider.newBackgroundContext()
        #expect(bg !== provider.viewContext)
    }
}

// MARK: - ManagedObjectStore Tests

@Suite("ManagedObjectStore")
struct ManagedObjectStoreTests {
    @Test("Create and fetch")
    func createAndFetch() {
        let store = makeStore()
        store.create { $0.name = "Alpha"; $0.value = 1 }
        store.save()

        let items = store.fetch()
        #expect(items.count == 1)
        #expect(items[0].name == "Alpha")
        #expect(items[0].value == 1)
    }

    @Test("Count with predicate")
    func countWithPredicate() {
        let store = makeStore()
        store.create { $0.name = "A"; $0.value = 10 }
        store.create { $0.name = "B"; $0.value = 20 }
        store.save()

        #expect(store.count() == 2)
        #expect(store.count(predicate: NSPredicate(format: "value > 15")) == 1)
    }

    @Test("First returns single item")
    func first() {
        let store = makeStore()
        store.create { $0.name = "Only"; $0.value = 42 }
        store.save()

        let item = store.first(predicate: NSPredicate(format: "name == %@", "Only"))
        #expect(item?.value == 42)

        let missing = store.first(predicate: NSPredicate(format: "name == %@", "Missing"))
        #expect(missing == nil)
    }

    @Test("Delete removes item")
    func delete() {
        let store = makeStore()
        let item = store.create { $0.name = "Temp"; $0.value = 0 }
        store.save()
        #expect(store.count() == 1)

        store.delete(item)
        store.save()
        #expect(store.count() == 0)
    }

    @Test("DeleteAll with predicate")
    func deleteAll() {
        let store = makeStore()
        store.create { $0.name = "Keep"; $0.value = 1 }
        store.create { $0.name = "Remove"; $0.value = 99 }
        store.create { $0.name = "Remove"; $0.value = 100 }
        store.save()

        store.deleteAll(predicate: NSPredicate(format: "value > 50"))
        store.save()
        #expect(store.count() == 1)
        #expect(store.first()?.name == "Keep")
    }

    @Test("Upsert creates or updates")
    func upsert() {
        let store = makeStore()

        store.upsert(predicate: NSPredicate(format: "name == %@", "Item")) {
            $0.name = "Item"; $0.value = 1
        }
        store.save()
        #expect(store.count() == 1)

        store.upsert(predicate: NSPredicate(format: "name == %@", "Item")) {
            $0.name = "Item"; $0.value = 99
        }
        store.save()
        #expect(store.count() == 1)
        #expect(store.first()?.value == 99)
    }

    @Test("Fetch with sort and limit")
    func fetchSortedLimited() {
        let store = makeStore()
        store.create { $0.name = "C"; $0.value = 3 }
        store.create { $0.name = "A"; $0.value = 1 }
        store.create { $0.name = "B"; $0.value = 2 }
        store.save()

        let sorted = store.fetch(sortDescriptors: [NSSortDescriptor(key: "value", ascending: true)], limit: 2)
        #expect(sorted.count == 2)
        #expect(sorted[0].name == "A")
        #expect(sorted[1].name == "B")
    }
}
