//
//  ViewController.swift
//  TodoSharing
//
//  Created by 原涼馬 on 2021/12/12.
//

import UIKit
import SkeletonView

// dara source
struct TodoInfo : Codable {
    var resultCount: Int = 0
    var results: [Todo] = [Todo]()
}

// レスポンスjsonに沿った型定義
struct Todo : Codable {
    var id: Int = 0
    var account_id: Int = 0
    var account_name: String = ""
    var todo: String = ""
    var detail: String? = ""
    var completed: Bool = false
}

class myCustomCell: UITableViewCell {
    @IBOutlet weak var todoText: UILabel!
    @IBOutlet weak var CheckBox: CheckBox!
}

class ViewController: UIViewController {
    @IBOutlet weak var todoTableView: UITableView!
    @IBOutlet weak var createTodoButton: UIButton!
    var loginBarButtonItem: UIBarButtonItem!
    var activityIndicatorView = UIActivityIndicatorView()
    // tableView表示用データソース
    var myDataSource = [[Todo]()]
    // ログインユーザー情報
    var loginAccountId: Int = 0;
    var loginAccountName: String = "";

    override func viewDidLoad() {
        super.viewDidLoad()
        // スケルトンビューの開始
        view.showAnimatedGradientSkeleton()
        todoTableView.showAnimatedSkeleton()
        
        // ログイン情報の取得
        loginAccountId = UserDefaults.standard.object(forKey: "account_id") as! Int
        loginAccountName = UserDefaults.standard.object(forKey: "account_name") as! String
        title = "Todoリスト"
        todoTableView.delegate = self
        todoTableView.dataSource = self
        todoTableView.rowHeight = UITableView.automaticDimension
        createTodoButton.layer.cornerRadius = 32
        // ログインボタンアイテムの初期化
        loginBarButtonItem = UIBarButtonItem(title: "ログアウト", style: .done, target: self, action: #selector(logoutBarButtonTapped(_:)))
        // ログインボタンアイテムの追加
        self.navigationItem.rightBarButtonItems = [loginBarButtonItem]

        view.addSubview(activityIndicatorView)
        configureRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        requestContents(delay: 2.0)
    }
    
    func configureRefreshControl () {
        //RefreshControlを追加する処理
        todoTableView.refreshControl = UIRefreshControl()
        todoTableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }

    @objc func handleRefreshControl() {
        requestContents(delay: 2.0)
        //上記の処理が終了したら下記が実行されます。
        DispatchQueue.main.async {
            self.todoTableView.reloadData()
            //TableViewの中身を更新する場合はここでリロード処理
            self.todoTableView.refreshControl?.endRefreshing()
        }
    }
    
    // ログアウトボタンが押された時の処理
    @objc func logoutBarButtonTapped(_ sender: UIBarButtonItem) {
        UserDefaults.standard.removeObject(forKey: "account_id")
        UserDefaults.standard.removeObject(forKey: "account_name")
        self.dismiss(animated: true, completion: nil)
    }
    
    // Todo新規登録ボタン押下時処理
    @IBAction func onTapCreatetodoButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let secondVC = storyboard.instantiateViewController(withIdentifier: "TodoDetailViewController") as? TodoDetailViewController {
            secondVC.todo = Todo(account_id: loginAccountId,
                                 account_name: loginAccountName)
            secondVC.isNew = true
            self.navigationController?.pushViewController(secondVC, animated: true)
        }
    }
    
    // CheckBox変更時処理
    @IBAction func checkView(_ sender: CheckBox) {
        let cell = sender.superview?.superview as! myCustomCell
        let indexPath = todoTableView.indexPath(for: cell)
        guard let section = indexPath?[0] else { return }
        guard let row = indexPath?[1] else { return }
        
        print(sender.isChecked)
        myDataSource[section][row].completed = !sender.isChecked
        updateTodo(todo: myDataSource[section][row])
    }
    

    // アラートダイアログを表示
    private func alert(title:String, message:String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: nil))
        present(alertController, animated: true)
    }
    
    // スケルトンを分かりやすくするためのdelay処理
    func delay(_ delay: Double, closure: @escaping ()->()) {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        closure()
      }
    }
    
    // Todo一覧取得処理
    func requestContents(delay: Double) {
        // リクエストurl作成
        guard let url = URL(string: "http://homestead.test/api/todos?account_id=\(loginAccountId)") else { return }
        // URLSessionクラスリクエスト
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else { return }
            if response.statusCode == 200 {
                // 取得結果をテーブルデータに変換
                let decoder = JSONDecoder()
                let results = try! decoder.decode([Todo].self, from: data)
                let todos = results.filter({(todo: Todo) -> Bool in
                    return !todo.completed
                })
                let completedTodos = results.filter({(todo: Todo) -> Bool in
                    return todo.completed
                })
                
                self.myDataSource = [todos]
                self.myDataSource.append(completedTodos)
                // UI更新メインスレッド実施
                DispatchQueue.main.async {
                    self.todoTableView.reloadData()
                    // スケルトン表示終了
                    self.delay(delay) {
                        self.view.hideSkeleton()
                        self.todoTableView.hideSkeleton()
                    }
                }
            } else {
                // エラーハンドリング
                print("登録データなし")
                print(response.statusCode)
            }
        }
        task.resume()
    }
    
    // todo更新処理
    private func updateTodo(todo: Todo) {
        print(todo)
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
            if response.statusCode == 200 {
                self.requestContents(delay: 0.0)
            } else {
                let message = "更新に失敗しました"
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: message)
                }
            }

        }
        task.resume()
    }
}

extension ViewController: UITableViewDataSource {
    // セクション数を返却
    func numberOfSections(in tableView: UITableView) -> Int {
        return myDataSource.count
    }
    // セクションごとの行数を返却
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myDataSource[section].count
    }
    // セクションのタイトルを返却
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Todo一覧"
        }
        return "完了したTodo一覧"
    }
    // 各行の表示データ(UITableViewCell)を返却
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // カスタムセルを生成
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "myCustomCell", for: indexPath) as? myCustomCell else {return
    UITableViewCell()}
        cell.showAnimatedSkeleton()
        cell.todoText.text = myDataSource[indexPath.section][indexPath.row].todo
        cell.CheckBox.isChecked = myDataSource[indexPath.section][indexPath.row].completed
        delay(2.0) {
            cell.hideSkeleton()
        }
    return cell
    }
}

extension ViewController: UITableViewDelegate {
     // cellの高さを返す
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    // セルがタップされた際に呼ばれる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let secondVC = storyboard.instantiateViewController(withIdentifier: "TodoDetailViewController") as? TodoDetailViewController {
            secondVC.todo = myDataSource[indexPath.section][indexPath.row]
            secondVC.isNew = false
            self.navigationController?.pushViewController(secondVC, animated: true)
        }
    }
}
