# ToDoList iOS (UIKit + VIPER + CoreData)

Реализовано приложение списка задач с требованиями:
- список задач (название, описание, дата создания, статус),
- добавление/редактирование/удаление,
- поиск,
- первичная загрузка из `https://dummyjson.com/todos`,
- фоновые операции для CRUD/поиска через `OperationQueue` + GCD,
- хранение и восстановление через CoreData,
- разбиение по слоям VIPER (View/Interactor/Presenter/Entity/Router).

## Структура
- `ToDoListApp/App` — запуск приложения
- `ToDoListApp/Core` — Entity, CoreData, Repository, API
- `ToDoListApp/TaskList` — VIPER-модуль списка задач

## Как запустить
1. Откройте `/Users/aleksejstepanov/Documents/Logbook/ToDoList/ToDoListApp.xcodeproj` в Xcode.
2. При необходимости задайте ваш `Team` и `Bundle Identifier` в Signing & Capabilities.
3. Запустите на симуляторе iPhone.

## Примечания
- Первый запуск импортирует задачи из API и сохраняет локально.
- Повторные запуски берут данные из CoreData.
- Поиск и все операции выполняются в фоне, UI не блокируется.
