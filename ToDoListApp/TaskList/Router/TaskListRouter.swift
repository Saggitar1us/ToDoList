import UIKit

final class TaskListRouter: TaskListRouterInput {
    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {
        let repository = TaskRepository()
        let interactor = TaskListInteractor(repository: repository)
        let router = TaskListRouter()
        let presenter = TaskListPresenter(interactor: interactor, router: router)
        let viewController = TaskListViewController(output: presenter)

        presenter.view = viewController
        interactor.output = presenter
        router.viewController = viewController

        return viewController
    }

    func showErrorAlert(from view: TaskListViewInput?, message: String) {
        guard let viewController else { return }
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
