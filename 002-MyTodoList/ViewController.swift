//
//  ViewController.swift
//  002-MyTodoList
//
//  Created by Takatoshi Miura on 2020/05/22.
//  Copyright © 2020 Takatoshi Miura. All rights reserved.
//
//  ＜概要＞
//  Todoリストを作成するプログラム。
//  「＋」ボタンをタップでTodoを入力するダイアログが表示され、OKボタンをタップでリストに追加される。
//  リストの内容は todoList という名前の配列に格納する。
//  リストデータの永続化はUserDefaultsを使用し、"todoList"という名前のキーを指定する。
//
//  ＜課題＞
//  ・達成済みのTodo、未達成のTodoの区別がつかない
//  ・リストに追加したTodoの削除ができない
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        //保存しているToDoの読み込み処理
        let userDefaults = UserDefaults.standard
        if let storedTodoList = userDefaults.array(forKey:"todoList") as? [String]{
            todoList.append(contentsOf:storedTodoList)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    //ToDoを格納した配列
    var todoList = [String]()
    
    
    //「＋」ボタンをタップした時の処理
    @IBAction func tapAddButton(_ sender: Any) {
        //アラートダイアログを生成
        let alertController = UIAlertController(title:"TODO追加",
                                                message:"ToDoを入力してください",
                                                preferredStyle:UIAlertController.Style.alert)
        //テキストエリアを追加
        alertController.addTextField(configurationHandler:nil)
        
        //OKボタンを追加
        let okAction = UIAlertAction(title:"OK",style:UIAlertAction.Style.default){
            (action:UIAlertAction)in
            //OKボタンがタップされたときの処理
            if let textField = alertController.textFields?.first {
                //TODOの配列に入力値を挿入。先頭に挿入する。
                self.todoList.insert(textField.text!,at:0)
                //テーブルに行が追加されたことをテーブルに通知
                self.tableView.insertRows(at:[IndexPath(row:0,section:0)],
                                          with:UITableView.RowAnimation.right)
                //ToDoの保存処理
                let userDefaults = UserDefaults.standard
                userDefaults.set(self.todoList,forKey:"todoList")
                userDefaults.synchronize()
            }
        }
        //OKボタンがタップされたときの処理
        alertController.addAction(okAction)
        
        //CANCELボタンを追加
        let cancelButton = UIAlertAction(title:"CANCEL",
                                         style:UIAlertAction.Style.cancel,
                                         handler:nil)
        //CANCELボタンがタップされた時の処理
        alertController.addAction(cancelButton)
        
        //アラートダイアログを表示
        present(alertController,animated:true,completion:nil)
    }
    
    
    //Todoの配列の長さ(項目の数)を返却する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList.count
    }
    
    
    //テーブルの行ごとのセルを返却する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Storyboardで指定したtodoCell識別子を利用して再利用可能なセルを取得する
        let cell = tableView.dequeueReusableCell(withIdentifier:"todoCell",for:indexPath)
        //行番号に合ったToDoのタイトルを取得
        let todoTitle = todoList[indexPath.row] //セルのラベルにToDoのタイトルをセット
        cell.textLabel?.text = todoTitle
        return cell
    }

}

