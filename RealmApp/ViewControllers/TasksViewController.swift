//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }

    private func getCurrentTask(for indexPath: IndexPath) -> Task {
        indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
    }
    
    private func getRowIndex(tasks: Results<Task>, task: Task) -> Int {
        tasks.firstIndex { tasker in
            tasker.date == task.date
        } ?? 0
    }
}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let title = task != nil ? "Edit Task" : "New Task"
        
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        alert.action(with: task) { [weak self] taskTitle, note in
            if let task = task, let completion = completion {
                StorageManager.shared.update(task, newName: taskTitle, newNote: note)
                completion()
            } else {
                self?.save(task: taskTitle, withNote: note)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(task: String, withNote note: String) {
        StorageManager.shared.save(task, withNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}

// MARK: - Table view data source
extension TasksViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showAlert(with: getCurrentTask(for: indexPath)) {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = getCurrentTask(for: indexPath)
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        let isFirstSection = indexPath.section == 0
        let doneAction = UIContextualAction(
            style: .normal,
            title: isFirstSection ? "Done" : "Undone"
        ) { [unowned self] _, _, isDone in
            StorageManager.shared.done(task)
            
            var rowIndex = isFirstSection
            ? getRowIndex(tasks: completedTasks, task: task)
            : getRowIndex(tasks: currentTasks, task: task)
            
            tableView.moveRow(at: indexPath, to: IndexPath(row: rowIndex, section: isFirstSection ? 1 : 0))
            isDone(true)
        }
        
        editAction.backgroundColor = UIColor.orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
}
