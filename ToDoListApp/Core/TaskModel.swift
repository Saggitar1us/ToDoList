import Foundation

struct TaskModel: Equatable {
    let id: UUID
    let remoteID: Int64?
    var title: String
    var details: String
    let createdAt: Date
    var isCompleted: Bool
}
