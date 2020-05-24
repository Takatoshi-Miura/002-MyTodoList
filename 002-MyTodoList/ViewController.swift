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
//  セルに表示されるチェックマークの有無によって達成済みと未達成のTodoを区別する。
//  MyTodoクラスを用意し、Todoの達成状況を格納する変数todoDoneを定義している。
//  MyTodoクラスのデータをUserDefaultsで保存するため、シリアライズ処理を行っている。
//
//  セルを左にスワイプすることでTodoを削除できる。
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        //保存しているToDoの読み込み処理
        let userDefaults = UserDefaults.standard
        if let storedTodoList = userDefaults.object(forKey:"todoList") as? Data{
            do {
                if let unarchiveTodoList = try NSKeyedUnarchiver.unarchivedObject(
                    ofClasses:[NSArray.self,MyTodo.self],
                from:storedTodoList) as? [MyTodo]{
                    todoList.append(contentsOf:unarchiveTodoList)
                }
            } catch {
                //エラー処理無し
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    //ToDoを格納した配列
    var todoList = [MyTodo]()
    
    
    //「＋」ボタンをタップした時の処理
    @IBAction func tapAddButton(_ sender: Any) {
        //アラートダイアログを生成
        let alertController = UIAlertController(title:"TODO追加",
                                                message:"ToDoを入力してください",
                                                preferredStyle:UIAlertController.Style.alert)
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
                self.tableView.insertRows(at: [IndexPath(row:0,section:0)],
                                          with: UITableView.RowAnimation.right)
                //ToDoの保存処理
                let userDefaults = UserDefaults.standard
                //Data型にシリアライズする
                do {
                let data = try NSKeyedArchiver.archivedData(
                    withRootObject:self.todoList,requiringSecureCoding:true)
                    userDefaults.set(data,forKey:"todoList")
                    userDefaults.synchronize()
                } catch {
                    //エラー処理なし
                }
            }
        }
        //OKボタンを追加
        alertController.addAction(okAction)
        
        //CANCELボタンを宣言
        let cancelButton = UIAlertAction(title:"CANCEL",
                                         style:UIAlertAction.Style.cancel,
                                         handler:nil)
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
        let myTodo = todoList[indexPath.row]
        if myTodo.todoDone {
            //完了済みの場合は未完了に変更
            myTodo.todoDone = false
        } else {
            //未完の場合は完了済みに変更
            myTodo.todoDone = true
        }
        //セルの状態を変更
        tableView.reloadRows(at:[indexPath],
                             with:UITableView.RowAnimation.fade)
        //データ保存。Data型にシリアライズする
        do {
            let data:Data = try NSKeyedArchiver.archivedData(
                withRootObject:todoList,requiringSecureCoding:true)
            //UserDefaultsに保存
            let userDefaults = UserDefaults.standard
            userDefaults.set(data,forKey:"todoList")
            userDefaults.synchronize()
        } catch {
            print("デバック:データの保存に失敗しました")
        }
    }
    
    
    //セルを削除したときの処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //削除処理かどうか
        if editingStyle == UITableViewCell.EditingStyle.delete {
            print("デバック:削除処理が行われました")
            //ToDoリストから削除
            todoList.remove(at:indexPath.row)
            //セルを削除
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            //データ保存。Data型にシリアライズする
            do {
                let data:Data = try NSKeyedArchiver.archivedData(
                    withRootObject:todoList,requiringSecureCoding:true)
                //UserDefaultsに保存
                let userDefaults = UserDefaults.standard
                userDefaults.set(data,forKey:"todoList")
                userDefaults.synchronize()
            } catch {
                //エラー処理なし
            }
        }
    }
    
}


//独自クラスをシリアライズする際には、NSObjectを継承し
//NSSecureCodingプロトコルに準拠する必要がある
class MyTodo:NSObject,NSSecureCoding{
    static var supportsSecureCoding:Bool{
        return true
    }

    var todoTitle:String?        //ToDoのタイトル
    var todoDone :Bool = false   //ToDoを完了したかどうかを表すフラグ
    
    override init(){
    }

    //NSCodingプロトコルに宣言されているデシリアライズ処理。デコード処理とも呼ばれる
    required init?(coder aDecoder:NSCoder){
        todoTitle = aDecoder.decodeObject(forKey:"todoTitle") as? String
        todoDone  = aDecoder.decodeBool(forKey:"todoDone")
    }
    //NSCodingプロトコルに宣言されているシリアライズ処理。エンコード処理とも呼ばれる
    func encode(with aCoder:NSCoder){
        aCoder.encode(todoTitle,forKey:"todoTitle")
        aCoder.encode(todoDone ,forKey:"todoDone")
    }
}


