import CoreData

@objc(TaskMO)
final class TaskMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var remoteID: NSNumber?
    @NSManaged var title: String
    @NSManaged var detailsText: String
    @NSManaged var createdAt: Date
    @NSManaged var isCompleted: Bool
}

extension TaskMO {
    static func fetchRequestAll() -> NSFetchRequest<TaskMO> {
        NSFetchRequest<TaskMO>(entityName: "TaskMO")
    }

    func toDomain() -> TaskModel {
        TaskModel(
            id: id,
            remoteID: remoteID?.int64Value,
            title: title,
            details: detailsText,
            createdAt: createdAt,
            isCompleted: isCompleted
        )
    }
}
