import CoreData
import Foundation

protocol TaskRepositoryProtocol {
    func bootstrapIfNeeded(completion: @escaping (Result<Void, Error>) -> Void)
    func fetchTasks(searchText: String?, completion: @escaping (Result<[TaskModel], Error>) -> Void)
    func createTask(title: String, details: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateTask(_ task: TaskModel, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteTask(id: UUID, completion: @escaping (Result<Void, Error>) -> Void)
}

enum TaskRepositoryError: Error {
    case taskNotFound
}

final class TaskRepository: TaskRepositoryProtocol {
    private enum Constants {
        static let importFlag = "didImportDummyTodos"
    }

    private let coreData: CoreDataStack
    private let service: DummyTodoServiceProtocol
    private let queue: OperationQueue
    private let userDefaults: UserDefaults

    init(
        coreData: CoreDataStack = .shared,
        service: DummyTodoServiceProtocol = DummyTodoService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.coreData = coreData
        self.service = service
        self.userDefaults = userDefaults

        let queue = OperationQueue()
        queue.name = "TaskRepositoryQueue"
        queue.maxConcurrentOperationCount = 1
        self.queue = queue
    }

    func bootstrapIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        if userDefaults.bool(forKey: Constants.importFlag) {
            DispatchQueue.main.async { completion(.success(())) }
            return
        }

        service.loadTodos { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }
            case .success(let todos):
                self.executeBackground(work: { context in
                    let request = TaskMO.fetchRequestAll()
                    request.fetchLimit = 1
                    let existingCount = try context.count(for: request)
                    guard existingCount == 0 else { return () }

                    for item in todos {
                        let task = TaskMO(context: context)
                        task.id = UUID()
                        task.remoteID = NSNumber(value: item.id)
                        task.title = item.todo
                        task.detailsText = "Imported from dummyjson (userId: \(item.userId))"
                        task.createdAt = Date()
                        task.isCompleted = item.completed
                    }
                    return ()
                }, completion: { [weak self] saveResult in
                    switch saveResult {
                    case .success:
                        self?.userDefaults.set(true, forKey: Constants.importFlag)
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
        }
    }

    func fetchTasks(searchText: String?, completion: @escaping (Result<[TaskModel], Error>) -> Void) {
        executeBackground(work: { context in
            let request = TaskMO.fetchRequestAll()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            if let searchText, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                request.predicate = NSPredicate(
                    format: "title CONTAINS[cd] %@ OR detailsText CONTAINS[cd] %@",
                    searchText,
                    searchText
                )
            }

            return try context.fetch(request).map { $0.toDomain() }
        }, completion: completion)
    }

    func createTask(title: String, details: String, completion: @escaping (Result<Void, Error>) -> Void) {
        executeBackground(work: { context in
            let task = TaskMO(context: context)
            task.id = UUID()
            task.remoteID = nil
            task.title = title
            task.detailsText = details
            task.createdAt = Date()
            task.isCompleted = false
            return ()
        }, completion: completion)
    }

    func updateTask(_ task: TaskModel, completion: @escaping (Result<Void, Error>) -> Void) {
        executeBackground(work: { context in
            let request = TaskMO.fetchRequestAll()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            guard let object = try context.fetch(request).first else {
                throw TaskRepositoryError.taskNotFound
            }

            object.title = task.title
            object.detailsText = task.details
            object.isCompleted = task.isCompleted
            return ()
        }, completion: completion)
    }

    func deleteTask(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        executeBackground(work: { context in
            let request = TaskMO.fetchRequestAll()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            guard let object = try context.fetch(request).first else {
                throw TaskRepositoryError.taskNotFound
            }

            context.delete(object)
            return ()
        }, completion: completion)
    }

    private func executeBackground<T>(
        work: @escaping (NSManagedObjectContext) throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        queue.addOperation { [weak self] in
            guard let self else { return }

            let group = DispatchGroup()
            group.enter()

            var operationResult: Result<T, Error>!
            self.coreData.container.performBackgroundTask { context in
                do {
                    let value = try work(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    operationResult = .success(value)
                } catch {
                    context.rollback()
                    operationResult = .failure(error)
                }
                group.leave()
            }

            group.wait()
            DispatchQueue.main.async {
                completion(operationResult)
            }
        }
    }
}
