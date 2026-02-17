import Foundation

protocol TaskListViewInput: AnyObject {
    func setLoading(_ isLoading: Bool)
    func showTasks(_ tasks: [TaskViewModel])
    func showError(message: String)
    func showTaskEditor(task: TaskModel?)
}

protocol TaskListViewOutput: AnyObject {
    func viewDidLoad()
    func didRequestAddTask()
    func didRequestEditTask(at index: Int)
    func didRequestDeleteTask(at index: Int)
    func didChangeSearch(text: String?)
    func didToggleTaskStatus(at index: Int)
    func didSubmitTaskForm(task: TaskModel?, title: String, details: String, isCompleted: Bool)
}

protocol TaskListRouterInput: AnyObject {
    func showErrorAlert(from view: TaskListViewInput?, message: String)
}

final class TaskListPresenter {
    weak var view: TaskListViewInput?

    private let interactor: TaskListInteractorInput
    private let router: TaskListRouterInput
    private let dateFormatter: DateFormatter

    private var tasks: [TaskModel] = []
    private var currentSearchText: String?

    init(interactor: TaskListInteractorInput, router: TaskListRouterInput) {
        self.interactor = interactor
        self.router = router

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        self.dateFormatter = formatter
    }

    private func render() {
        let viewModels = tasks.map {
            TaskViewModel(
                id: $0.id,
                title: $0.title,
                details: $0.details,
                createdAtText: dateFormatter.string(from: $0.createdAt),
                isCompleted: $0.isCompleted
            )
        }
        view?.showTasks(viewModels)
    }
}

extension TaskListPresenter: TaskListViewOutput {
    func viewDidLoad() {
        view?.setLoading(true)
        interactor.bootstrapIfNeeded()
    }

    func didRequestAddTask() {
        view?.showTaskEditor(task: nil)
    }

    func didRequestEditTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        view?.showTaskEditor(task: tasks[index])
    }

    func didRequestDeleteTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        interactor.deleteTask(id: tasks[index].id)
    }

    func didChangeSearch(text: String?) {
        currentSearchText = text
        interactor.loadTasks(searchText: text)
    }

    func didToggleTaskStatus(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        var task = tasks[index]
        task.isCompleted.toggle()
        interactor.updateTask(task)
    }

    func didSubmitTaskForm(task: TaskModel?, title: String, details: String, isCompleted: Bool) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            view?.showError(message: "Название задачи не может быть пустым")
            return
        }

        if var existing = task {
            existing.title = trimmedTitle
            existing.details = details
            existing.isCompleted = isCompleted
            interactor.updateTask(existing)
        } else {
            interactor.createTask(title: trimmedTitle, details: details)
        }
    }
}

extension TaskListPresenter: TaskListInteractorOutput {
    func interactorDidFinishBootstrap() {
        interactor.loadTasks(searchText: currentSearchText)
    }

    func interactorDidLoad(tasks: [TaskModel]) {
        self.tasks = tasks
        view?.setLoading(false)
        render()
    }

    func interactorDidFail(with error: Error) {
        view?.setLoading(false)
        router.showErrorAlert(from: view, message: error.localizedDescription)
    }
}
