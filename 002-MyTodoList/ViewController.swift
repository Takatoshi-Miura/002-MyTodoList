//
//  ViewController.swift
//  002-MyTodoList
//
//  Created by Takatoshi Miura on 2020/05/22.
//  Copyright © 2020 Takatoshi Miura. All rights reserved.
//
//  ＜概要＞
//  Todoリストを作成するプログラム。
//  「＋」ボタンをタップでTodoを入力するダイアログが表示され、内容を入力後OKボタンタップでリストに追加される。
//  セルをタップする毎にチェックマークの有無が切り替わることで、達成度がわかる。
//  セルを左にスワイプすることでTodoを削除できる。
//  リストのデータはFirebaseのRealtime Databeseに保存される。
//
//  Todoを作成する毎にMyTodoクラスのオブジェクトが生成される。
//  Todoにはそれぞれ固有のIDを設定することによって区別する。
//  固有IDは一度設定されたら削除されるまで変更されることはなく、Todo作成毎に1から昇順に割り当てられる。
//  アプリ起動時にデータベースからデータを読み取るが、このとき固有IDの最大値を取得することで、IDの重複を防止する。
//
//  ＜課題＞
//  Todoが削除されることで固有IDの空き番号が出てくる。
//  新しいTodoを追加する際に、その空き番号を優先的に割り当てるようにしたい。
//  現状では、Int型の範囲を超える個数のTodoは扱うことができない。
//

import UIKit
import Firebase

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //保存しているToDoの読み込み処理
        for todoID in 0...100 {
            Database.database().reference().child("user/\(todoID)").observeSingleEvent(of:.value, with:{(snapshot) in
                if let data = snapshot.value as? [String:AnyObject]{
                    //データベースのデータを元にリストを作成する
                    //データベースに保存されている固有IDを反映する
                    let myTodo = MyTodo(todoID)
                    //Todoの内容と達成度をデータベースから読み取る
                    myTodo.todoTitle = data["myTodo"] as? String
                    myTodo.todoDone  = data["todoDone"] as! NSObject as! Bool
                    //リストに追加し、テーブルに反映
                    self.todoList.insert(myTodo,at:0)
                    self.tableView.insertRows(at: [IndexPath(row:0,section:0)],with: UITableView.RowAnimation.right)
                }
            }, withCancel: nil)
        }
        
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    //ToDoを格納した配列
    var todoList = [MyTodo]()
    
    //「＋」ボタンをタップした時の処理
    @IBAction func tapAddButton(_ sender: Any) {
        //アラートダイアログを生成
        let alertController = UIAlertController(title:"TODO追加",message:"ToDoを入力してください",preferredStyle:UIAlertController.Style.alert)
        //テキストエリアを追加
        alertController.addTextField(configurationHandler:nil)
        
        //OKボタンを宣言
        let okAction = UIAlertAction(title:"OK",style:UIAlertAction.Style.default){
            (action:UIAlertAction)in
            //OKボタンがタップされたときの処理
            if let textField = alertController.textFields?.first {
                //ToDoの配列に入力値を挿入。先頭に挿入する
                let myTodo = MyTodo()
                myTodo.todoTitle = textField.text!
                self.todoList.insert(myTodo,at:0)
                //テーブルに行が追加されたことをテーブルに通知
                self.tableView.insertRows(at: [IndexPath(row:0,section:0)],with: UITableView.RowAnimation.right)
                //Todoの内容と達成度をデータベースに保存
                let databaseReference:DatabaseReference! = Database.database().reference()
                let titleData = ["\(myTodo.getTodoID())/myTodo":myTodo.todoTitle]
                let doneData  = ["\(myTodo.getTodoID())/todoDone":myTodo.todoDone]
                databaseReference.child("user").updateChildValues(titleData as [AnyHashable : Any])
                databaseReference.child("user").updateChildValues(doneData)
            }
        }
        //OKボタンを追加
        alertController.addAction(okAction)
        
        //CANCELボタンを宣言
        let cancelButton = UIAlertAction(title:"CANCEL",style:UIAlertAction.Style.cancel,handler:nil)
        //CANCELボタンを追加
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath)
        //行番号に合ったToDoの情報を取得
        let myTodo = todoList[indexPath.row] //セルのラベルにToDoのタイトルをセット
        cell.textLabel?.text = myTodo.todoTitle
        //セルのチェックマーク状態をセット
        if myTodo.todoDone{
            //チェックあり
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            //チェックなし
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        return cell
    }

    
    //セルをタップしたときの処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Todoが達成済みなら未達成に、未達成なら達成済みに変更
        let myTodo = todoList[indexPath.row]
        if myTodo.todoDone {
            myTodo.todoDone = false
        } else {
            myTodo.todoDone = true
        }
        //セルの状態を変更
        tableView.reloadRows(at:[indexPath],with:UITableView.RowAnimation.fade)
        //Todoの達成度をデータベースに保存
        let databaseReference:DatabaseReference! = Database.database().reference()
        let doneData = ["\(myTodo.getTodoID())/todoDone":myTodo.todoDone]
        databaseReference.child("user").updateChildValues(doneData)
    }
    
    
    //セルを削除したときの処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //削除処理かどうか
        if editingStyle == UITableViewCell.EditingStyle.delete {
            //データベースのデータを削除
            let databaseReference:DatabaseReference! = Database.database().reference()
            databaseReference.child("user/\(todoList[indexPath.row].getTodoID())").removeValue()
            //ToDoリストから削除
            todoList.remove(at:indexPath.row)
            //セルを削除
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }
    
}


//固有IDを設定することによってTodoを区別する
class MyTodo {
    
    static var supportsSecureCoding:Bool{
        return true
    }

    static var todoCount:Int = 0 //登録したTodoの総合計
    private let todoID:Int       //Todoの固有ID。一度設定したらTodoが削除されるまで不変なため定数で宣言。
    var todoTitle:String?        //ToDoのタイトル
    var todoDone:Bool = false    //ToDoを完了したかどうかを表すフラグ
    
    //Todo作成時の処理。固有IDの割り当て。
    init(){
        MyTodo.todoCount += 1
        self.todoID = MyTodo.todoCount
    }
    
    //データベースからの読み取り用
    init(_ todoID:Int){
        self.todoID = todoID
        //todoIDの最大値をtodoCountに設定することで、todoIDの重複を防止
        if todoID > MyTodo.todoCount {
            MyTodo.todoCount = todoID
        }
    }
    
    //固有IDのゲッター
    public func getTodoID() -> Int {
        return self.todoID
    }

}


