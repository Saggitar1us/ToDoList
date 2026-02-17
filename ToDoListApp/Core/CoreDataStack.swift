import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ToDoListModel", managedObjectModel: model)

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent store: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let taskEntity = NSEntityDescription()
        taskEntity.name = "TaskMO"
        taskEntity.managedObjectClassName = NSStringFromClass(TaskMO.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let remoteID = NSAttributeDescription()
        remoteID.name = "remoteID"
        remoteID.attributeType = .integer64AttributeType
        remoteID.isOptional = true

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false

        let detailsText = NSAttributeDescription()
        detailsText.name = "detailsText"
        detailsText.attributeType = .stringAttributeType
        detailsText.isOptional = false

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let isCompleted = NSAttributeDescription()
        isCompleted.name = "isCompleted"
        isCompleted.attributeType = .booleanAttributeType
        isCompleted.isOptional = false

        taskEntity.properties = [id, remoteID, title, detailsText, createdAt, isCompleted]
        model.entities = [taskEntity]
        return model
    }
}
