import XCTest
@testable import ToDoListApp

final class TaskListInteractorTests: XCTestCase {
    func testBootstrapSuccessNotifiesOutput() {
        let repository = RepositoryMock()
        repository.bootstrapResult = .success(())
        let output = OutputSpy()
        let sut = TaskListInteractor(repository: repository)
        sut.output = output

        sut.bootstrapIfNeeded()

        XCTAssertEqual(output.events, [.didFinishBootstrap])
    }

    func testLoadTasksPassesSearchTextAndReturnsTasks() {
        let repository = RepositoryMock()
        let output = OutputSpy()
        let sut = TaskListInteractor(repository: repository)
        sut.output = output

        let task = makeTask(title: "Buy milk")
        repository.fetchResult = .success([task])

        sut.loadTasks(searchText: "milk")

        XCTAssertEqual(repository.fetchSearchTexts, ["milk"])
        XCTAssertEqual(output.loadedTasks, [[task]])
    }

    func testCreateTaskReloadsUsingLastSearchText() {
        let repository = RepositoryMock()
        let output = OutputSpy()
        let sut = TaskListInteractor(repository: repository)
        sut.output = output

        repository.fetchResult = .success([])

        sut.loadTasks(searchText: "urgent")
        sut.createTask(title: "Title", details: "Details")

        XCTAssertEqual(repository.createdTasks.count, 1)
        XCTAssertEqual(repository.fetchSearchTexts, ["urgent", "urgent"])
    }

    func testDeleteTaskFailureForwardsErrorToOutput() {
        let repository = RepositoryMock()
        let output = OutputSpy()
        let sut = TaskListInteractor(repository: repository)
        sut.output = output

        let expectedError = DummyError()
        repository.deleteResult = .failure(expectedError)

        sut.deleteTask(id: UUID())

        XCTAssertEqual(output.events, [.didFail])
        XCTAssertNotNil(output.lastError)
    }
}

private final class RepositoryMock: TaskRepositoryProtocol {
    var bootstrapResult: Result<Void, Error> = .success(())
    var fetchResult: Result<[TaskModel], Error> = .success([])
    var createResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())

    var fetchSearchTexts: [String?] = []
    var createdTasks: [(title: String, details: String)] = []

    func bootstrapIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(bootstrapResult)
    }

    func fetchTasks(searchText: String?, completion: @escaping (Result<[TaskModel], Error>) -> Void) {
        fetchSearchTexts.append(searchText)
        completion(fetchResult)
    }

    func createTask(title: String, details: String, completion: @escaping (Result<Void, Error>) -> Void) {
        createdTasks.append((title: title, details: details))
        completion(createResult)
    }

    func updateTask(_ task: TaskModel, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(updateResult)
    }

    func deleteTask(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(deleteResult)
    }
}

private final class OutputSpy: TaskListInteractorOutput {
    enum Event: Equatable {
        case didFinishBootstrap
        case didFail
    }

    var events: [Event] = []
    var loadedTasks: [[TaskModel]] = []
    var lastError: Error?

    func interactorDidFinishBootstrap() {
        events.append(.didFinishBootstrap)
    }

    func interactorDidLoad(tasks: [TaskModel]) {
        loadedTasks.append(tasks)
    }

    func interactorDidFail(with error: Error) {
        events.append(.didFail)
        lastError = error
    }
}

private struct DummyError: Error {}

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
