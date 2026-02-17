import XCTest
@testable import ToDoListApp

final class TaskListPresenterTests: XCTestCase {
    func testViewDidLoadStartsLoadingAndBootstraps() {
        let view = ViewSpy()
        let interactor = InteractorMock()
        let router = RouterSpy()
        let sut = TaskListPresenter(interactor: interactor, router: router)
        sut.view = view

        sut.viewDidLoad()

        XCTAssertEqual(view.loadingStates, [true])
        XCTAssertEqual(interactor.bootstrapCalls, 1)
    }

    func testSubmitTaskFormWithEmptyTitleShowsValidationError() {
        let view = ViewSpy()
        let interactor = InteractorMock()
        let router = RouterSpy()
        let sut = TaskListPresenter(interactor: interactor, router: router)
        sut.view = view

        sut.didSubmitTaskForm(task: nil, title: "   ", details: "d", isCompleted: false)

        XCTAssertEqual(view.errorMessages, ["Название задачи не может быть пустым"])
        XCTAssertTrue(interactor.createdTasks.isEmpty)
        XCTAssertTrue(interactor.updatedTasks.isEmpty)
    }

    func testSubmitTaskFormForNewTaskTrimsTitleAndCreatesTask() {
        let view = ViewSpy()
        let interactor = InteractorMock()
        let router = RouterSpy()
        let sut = TaskListPresenter(interactor: interactor, router: router)
        sut.view = view

        sut.didSubmitTaskForm(task: nil, title: "  New Task  ", details: "Details", isCompleted: false)

        XCTAssertEqual(interactor.createdTasks.count, 1)
        XCTAssertEqual(interactor.createdTasks.first?.title, "New Task")
        XCTAssertEqual(interactor.createdTasks.first?.details, "Details")
    }

    func testDidToggleTaskStatusSendsUpdatedTaskToInteractor() {
        let view = ViewSpy()
        let interactor = InteractorMock()
        let router = RouterSpy()
        let sut = TaskListPresenter(interactor: interactor, router: router)
        sut.view = view

        let task = makeTask(title: "Toggle me", completed: false)
        sut.interactorDidLoad(tasks: [task])

        sut.didToggleTaskStatus(at: 0)

        XCTAssertEqual(interactor.updatedTasks.count, 1)
        XCTAssertEqual(interactor.updatedTasks.first?.id, task.id)
        XCTAssertEqual(interactor.updatedTasks.first?.isCompleted, true)
    }

    func testInteractorFailureStopsLoadingAndShowsErrorViaRouter() {
        let view = ViewSpy()
        let interactor = InteractorMock()
        let router = RouterSpy()
        let sut = TaskListPresenter(interactor: interactor, router: router)
        sut.view = view

        sut.interactorDidFail(with: PresenterError())

        XCTAssertEqual(view.loadingStates.last, false)
        XCTAssertEqual(router.messages.count, 1)
    }
}

private final class ViewSpy: TaskListViewInput {
    var loadingStates: [Bool] = []
    var shownTasks: [[TaskViewModel]] = []
    var errorMessages: [String] = []
    var editedTasks: [TaskModel?] = []

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showTasks(_ tasks: [TaskViewModel]) {
        shownTasks.append(tasks)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }

    func showTaskEditor(task: TaskModel?) {
        editedTasks.append(task)
    }
}

private final class InteractorMock: TaskListInteractorInput {
    var bootstrapCalls = 0
    var loadCalls: [String?] = []
    var createdTasks: [(title: String, details: String)] = []
    var updatedTasks: [TaskModel] = []
    var deletedTaskIDs: [UUID] = []

    func bootstrapIfNeeded() {
        bootstrapCalls += 1
    }

    func loadTasks(searchText: String?) {
        loadCalls.append(searchText)
    }

    func createTask(title: String, details: String) {
        createdTasks.append((title: title, details: details))
    }

    func updateTask(_ task: TaskModel) {
        updatedTasks.append(task)
    }

    func deleteTask(id: UUID) {
        deletedTaskIDs.append(id)
    }
}

private final class RouterSpy: TaskListRouterInput {
    var messages: [String] = []

    func showErrorAlert(from view: TaskListViewInput?, message: String) {
        messages.append(message)
    }
}

private struct PresenterError: LocalizedError {
    var errorDescription: String? { "Presenter error" }
}

private func makeTask(title: String, completed: Bool = false) -> TaskModel {
    TaskModel(
        id: UUID(),
        remoteID: nil,
        title: title,
        details: "Details",
        createdAt: Date(timeIntervalSince1970: 1),
        isCompleted: completed
    )
}
