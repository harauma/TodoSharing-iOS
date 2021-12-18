//
//  File.swift
//  TodoSharing
//
//  Created by 原涼馬 on 2021/12/13.
//

import UIKit

class TodoTableViewController: UITableViewController {
    weak var viewController: ViewController?
  override func viewDidLoad() {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: Selector(("refreshTable")), for: UIControl.Event.valueChanged)
    self.refreshControl = refreshControl
  }
  @objc func refreshTable() {
      
      // 更新処理
      viewController?.requestContents()
 
      // クルクルを止める
      refreshControl?.endRefreshing()
  }
}
