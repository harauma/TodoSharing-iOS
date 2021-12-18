//
//  TodoDetailViewController.swift
//  TodoSharing
//
//  Created by 原涼馬 on 2021/12/13.
//

import UIKit

struct RequestData: Codable {
    var todo: Todo = Todo()
}

class TodoDetailViewController: UIViewController {
    @IBOutlet weak var accountNameText: UILabel!
    @IBOutlet weak var todoText: UITextField!
    @IBOutlet weak var todoDetailText: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    var todo: Todo = Todo()
    var isNew: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    private func initViews() {
        title = "Todo詳細"
        if (isNew) {
            submitButton.setTitle("新規登録", for: .normal)
        } else {
            todoText.text = todo.todo
            todoDetailText.text = todo.detail
        }
        todoText.layer.borderColor = UIColor.lightGray.cgColor
        todoText.layer.borderWidth = 1.0;
        todoText.layer.cornerRadius = 5.0;
        todoDetailText.layer.borderColor = UIColor.lightGray.cgColor
        todoDetailText.layer.borderWidth = 1.0;
        todoDetailText.layer.cornerRadius = 5.0;
        accountNameText.text = todo.account_name
        deleteButton.isHidden = isNew
    }

    @IBAction func onTapSubmitButton(_ sender: UIButton) {
        guard let unwrappedTodo = todoText.text else { return }
        guard let unwrappedTodoDetail = todoDetailText.text else { return }
        
        todo.todo = unwrappedTodo
        todo.detail = unwrappedTodoDetail
        if (todoText.text! == "") {
            self.alert(title: "エラー", message: "Todoが入力されていません", doPopView: false)
            return
        }
        if (isNew) {
            print("create")
            createTodo()
        } else {
            updateTodo()
        }
    }
    
    @IBAction func onTapDeleteButton(_ sender: UIButton) {
        print("削除ボタン押下された")
        print(todo)
        deleteTodo()
    }
    
    private func createTodo() {
        let data = RequestData(todo: todo)
        // リクエストurl作成
        guard let url = URL(string: "http://homestead.test/api/todos") else { return }
        guard let jsonData = try? JSONEncoder().encode(data) else {
            print("Error: Trying to convert model to JSON data")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        // URLSessionクラス䛷リクエスト
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "通信エラー")
                }
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            var title = ""
            var message = ""
            if response.statusCode == 201 {
                message = "登録に成功しました"
            } else {
                title = "エラー"
                message = "登録に失敗しました"
            }
            DispatchQueue.main.async {
                self.alert(title: title, message: message)
            }
        }
        task.resume()
    }
    
    private func updateTodo() {
        let data = RequestData(todo: todo)
        // リクエストurl作成
        guard let url = URL(string: "http://homestead.test/api/todos/\(todo.id)") else { return }
        guard let jsonData = try? JSONEncoder().encode(data) else {
            print("Error: Trying to convert model to JSON data")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        // URLSessionクラスリクエスト
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "通信エラー")
                }
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            var title = ""
            var message = ""
            if response.statusCode == 200 {
                message = "更新に成功しました"
            } else {
                title = "エラー"
                message = "更新に失敗しました"
            }
            DispatchQueue.main.async {
                self.alert(title: title, message: message)
            }
        }
        task.resume()
    }
    
    private func deleteTodo() {
        // リクエストurl作成
        guard let url = URL(string: "http://homestead.test/api/todos/\(todo.id)") else { return }
        guard let jsonData = try? JSONEncoder().encode(todo) else {
            print("Error: Trying to convert model to JSON data")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        // URLSessionクラスリクエスト
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "通信エラー")
                }
                return
            }
            guard let response = response as? HTTPURLResponse else { return }
            var title = ""
            var message = ""
            if response.statusCode == 204 {
                message = "削除に成功しました"
            } else {
                title = "エラー"
                message = "削除に失敗しました"
            }
            DispatchQueue.main.async {
                self.alert(title: title, message: message)
            }
        }
        task.resume()
    }
    
    private func alert(title: String, message: String, doPopView: Bool = true) {
        // OKボタン押下時に1つ前の画面に戻る処理
        let handler = doPopView ? {(action: UIAlertAction!) -> Void in
            self.navigationController?.popViewController(animated: true)} : nil
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: handler))
        present(alertController, animated: true)
    }
}
