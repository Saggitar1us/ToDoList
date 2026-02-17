import UIKit

final class TaskListViewController: UIViewController {
    private enum Constants {
        static let cellId = "TaskCell"
    }

    private let output: TaskListViewOutput
    private var viewModels: [TaskViewModel] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellId)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = "Поиск задач"
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        return controller
    }()

    init(output: TaskListViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        output.viewDidLoad()
    }

    private func configureUI() {
        title = "ToDo List"
        view.backgroundColor = .systemBackground

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc
    private func didTapAdd() {
        output.didRequestAddTask()
    }

    private func presentTaskEditor(task: TaskModel?) {
        let title = task == nil ? "Новая задача" : "Редактировать"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alert.addTextField { field in
            field.placeholder = "Название"
            field.text = task?.title
        }

        alert.addTextField { field in
            field.placeholder = "Описание"
            field.text = task?.details
        }

        let initialCompleted = task?.isCompleted ?? false
        let statusActionTitle = initialCompleted ? "Снять выполнение" : "Отметить выполненной"

        alert.addAction(UIAlertAction(title: statusActionTitle, style: .default) { [weak self, weak alert] _ in
            guard
                let self,
                let textFields = alert?.textFields,
                textFields.count == 2
            else { return }

            let taskTitle = textFields[0].text ?? ""
            let details = textFields[1].text ?? ""
            self.output.didSubmitTaskForm(task: task, title: taskTitle, details: details, isCompleted: !initialCompleted)
        })

        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self, weak alert] _ in
            guard
                let self,
                let textFields = alert?.textFields,
                textFields.count == 2
            else { return }

            let taskTitle = textFields[0].text ?? ""
            let details = textFields[1].text ?? ""
            self.output.didSubmitTaskForm(task: task, title: taskTitle, details: details, isCompleted: initialCompleted)
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

extension TaskListViewController: TaskListViewInput {
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func showTasks(_ tasks: [TaskViewModel]) {
        viewModels = tasks
        tableView.reloadData()
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showTaskEditor(task: TaskModel?) {
        presentTaskEditor(task: task)
    }
}

extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellId, for: indexPath)
        let item = viewModels[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        let statusText = item.isCompleted ? "выполнена" : "не выполнена"
        content.secondaryText = "\(item.details)\nСоздано: \(item.createdAtText) • Статус: \(statusText)"
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryType = item.isCompleted ? .checkmark : .none
        return cell
    }
}

extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        output.didRequestEditTask(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.output.didRequestDeleteTask(at: indexPath.row)
            completion(true)
        }

        let toggleAction = UIContextualAction(style: .normal, title: "Статус") { [weak self] _, _, completion in
            self?.output.didToggleTaskStatus(at: indexPath.row)
            completion(true)
        }

        toggleAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteAction, toggleAction])
    }
}

extension TaskListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        output.didChangeSearch(text: searchController.searchBar.text)
    }
}
