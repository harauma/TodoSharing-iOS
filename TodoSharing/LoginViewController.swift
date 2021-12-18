//
//  LoginViewController.swift
//  TodoSharing
//
//  Created by 原涼馬 on 2021/12/14.
//

import UIKit

struct UserInfo : Codable {
    var id: Int = 0
    var name: String = ""
}

struct LoginInfo : Codable {
    var login_id: String = ""
    var password: String = ""
}

class LoginViewController: UIViewController {
    @IBOutlet weak var loginIdText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onTapLoginButton(_ sender: UIButton) {
        if (loginIdText.text! == "") {
            alert(title: "エラー", message: "ユーザーIDを入力してください")
            return
        }
        
        if (passwordText.text! == "") {
            alert(title: "エラー", message: "パスワードを入力してください")
            return
        }
        login()
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
    
    private func login() {
        let data = LoginInfo(login_id: loginIdText.text!, password: passwordText.text!)
        // リクエストurl作成
        guard let url = URL(string: "http://homestead.test/api/login") else { return }
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
                    self.alert(title: "", message: "通信エラー")
                }
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else { return }
            var message = ""
            print(response.statusCode)
            if response.statusCode == 200 {
                let loginUser = try! JSONDecoder().decode(UserInfo.self, from: data)
                let ud = UserDefaults.standard
                //ユーザーID、ユーザー名をUDに保存
                ud.set(loginUser.id, forKey: "account_id")
                ud.set(loginUser.name, forKey: "account_name")
                //次の画面に遷移する
                DispatchQueue.main.async {
                    let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "navigationcontroller") as! UINavigationController
                    secondViewController.modalPresentationStyle = .fullScreen
                    self.present(secondViewController, animated: true, completion: nil)
                }
            } else {
                message = "ログインに失敗しました"            }
            DispatchQueue.main.async {
                self.alert(title: "エラー", message: message)
            }
        }
        task.resume()
    }
}
