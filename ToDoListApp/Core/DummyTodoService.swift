import Foundation

protocol DummyTodoServiceProtocol {
    func loadTodos(completion: @escaping (Result<[DummyTodoDTO], Error>) -> Void)
}

struct DummyTodoDTO: Decodable {
    let id: Int64
    let todo: String
    let completed: Bool
    let userId: Int64
}

private struct DummyTodoResponse: Decodable {
    let todos: [DummyTodoDTO]
}

final class DummyTodoService: DummyTodoServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadTodos(completion: @escaping (Result<[DummyTodoDTO], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            completion(loadFromBundle().mapError { $0 as Error })
            return
        }

        session.dataTask(with: url) { data, _, error in
            if let error {
                completion(self.loadFromBundle().mapError { _ in error })
                return
            }

            guard let data else {
                completion(self.loadFromBundle().mapError { _ in URLError(.badServerResponse) })
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DummyTodoResponse.self, from: data)
                completion(.success(decoded.todos))
            } catch {
                completion(self.loadFromBundle().mapError { _ in error })
            }
        }.resume()
    }

    private func loadFromBundle() -> Result<[DummyTodoDTO], Error> {
        guard let url = Bundle.main.url(forResource: "todos", withExtension: "json") else {
            return .failure(URLError(.fileDoesNotExist))
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(DummyTodoResponse.self, from: data)
            return .success(decoded.todos)
        } catch {
            return .failure(error)
        }
    }
}
