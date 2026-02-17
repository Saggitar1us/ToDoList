import Foundation

protocol TaskListInteractorInput: AnyObject {
    func bootstrapIfNeeded()
    func loadTasks(searchText: String?)
    func createTask(title: String, details: String)
    func updateTask(_ task: TaskModel)
    func deleteTask(id: UUID)
}

protocol TaskListInteractorOutput: AnyObject {
    func interactorDidFinishBootstrap()
    func interactorDidLoad(tasks: [TaskModel])
    func interactorDidFail(with error: Error)
}

final class TaskListInteractor: TaskListInteractorInput {
    weak var output: TaskListInteractorOutput?

    private let repository: TaskRepositoryProtocol
    private var lastSearchText: String?

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    func bootstrapIfNeeded() {
        repository.bootstrapIfNeeded { [weak self] result in
            switch result {
            case .success:
                self?.output?.interactorDidFinishBootstrap()
            case .failure(let error):
                self?.output?.interactorDidFail(with: error)
            }
        }
    }

    func loadTasks(searchText: String?) {
        lastSearchText = searchText
        repository.fetchTasks(searchText: searchText) { [weak self] result in
            switch result {
            case .success(let tasks):
                self?.output?.interactorDidLoad(tasks: tasks)
            case .failure(let error):
                self?.output?.interactorDidFail(with: error)
            }
        }
    }

    func createTask(title: String, details: String) {
        repository.createTask(title: title, details: details) { [weak self] result in
            switch result {
            case .success:
                self?.loadTasks(searchText: self?.lastSearchText)
            case .failure(let error):
                self?.output?.interactorDidFail(with: error)
            }
        }
    }

    func updateTask(_ task: TaskModel) {
        repository.updateTask(task) { [weak self] result in
            switch result {
            case .success:
                self?.loadTasks(searchText: self?.lastSearchText)
            case .failure(let error):
                self?.output?.interactorDidFail(with: error)
            }
        }
    }

    func deleteTask(id: UUID) {
        repository.deleteTask(id: id) { [weak self] result in
            switch result {
            case .success:
                self?.loadTasks(searchText: self?.lastSearchText)
            case .failure(let error):
                self?.output?.interactorDidFail(with: error)
            }
        }
    }
}
