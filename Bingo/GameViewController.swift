//
//  ViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 2/1/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import CoreData

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!

    var alphabet = [String]()
    var data = [String](repeating: "", count: 25)
    var cubeList:[LetterCube] = [LetterCube]()
    var collection:[LetterCube] = [LetterCube]()
    var wordList:[String] = [String]()
    var disabled:Bool = false
    var gameOverAlert:UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let array = (appDelegate.currentGame?.words.components(separatedBy: ","))!
        for string in array {
            let trimmedString = string.trimmingCharacters(in: CharacterSet.whitespaces)
            alphabet.append(trimmedString)

        }
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.playerJoined(_:)), name: NSNotification.Name(rawValue: "playerJoined"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.playerLeft(_:)), name: NSNotification.Name(rawValue: "playerLeft"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.playerWon(_:)), name: NSNotification.Name(rawValue: "win"), object: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        var used = [Int]();
        var i = 0;
        while(i < 25) {
            if (i == 12) {
                data[12] = "FREE"
                i += 1
            }
            else {
                let pick = Int(arc4random_uniform(UInt32(alphabet.count)))
                if (!used.contains(pick) || used.count >= alphabet.count) {
                    used.append(pick);
                    data[i] = alphabet[pick]
                    i += 1
                }
            }
        }

        cubeList.removeAll()
        collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: InviteViewController.self) {
            let dvc:InviteViewController = segue.destination as! InviteViewController
            dvc.gameOngoing = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()

    }
    
    func playerJoined(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo as? Dictionary<String, String>
        {
            if let playerName = userInfo["name"] as String? {
                let alert = UIAlertController(title: playerName + " has joined", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true, completion: { () -> Void in
                    self.perform(#selector(GameViewController.dismissNotification), with: nil, afterDelay: 1.0)
                })
            }
        }
    }
    
    func playerLeft(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo as? Dictionary<String, String>
        {
            if let playerName = userInfo["name"] as String? {
                let alert = UIAlertController(title: playerName + " has left the game", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true, completion: { () -> Void in
                    self.perform(#selector(GameViewController.dismissNotification), with: nil, afterDelay: 1.0)
                })
            }
        }
    }
    
    func playerWon(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo as? Dictionary<String, String>
        {
            if let playerName = userInfo["name"] as String?, let answers = userInfo["answers"] as String? {
                let alert = UIAlertController(title: playerName + " won!", message: "answers: " + answers, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                    (alert: UIAlertAction!) in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.endGame()
                    _ = self.navigationController?.popToRootViewController(animated: true)
                    
                }))
                self.present(alert, animated: true, completion:nil)
            }
        }
    }
    
    func dismissNotification() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for cell in collectionView.visibleCells
        {
            (cell as! LetterCube).titleLabel.adjustFont()
        }
        if (gameOverAlert != nil) {
            present(gameOverAlert!, animated: true, completion:nil)
        }
    }
    
    @IBAction func leaveGameTapped(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func checkForWin() {
        
        //horizontal rows
        var winning = [String]()
        var won = [[String]]()
        
        for i in stride(from: 0, to: 25, by: 5) {
            for j in stride(from: i, to: i+5, by: 1) {
                if cubeList.contains(collection[j]) {
                    winning.append(data[j])
                }
                else {
                    break
                }
            }
            if winning.count == 5 {
                let copy = winning
                won.append(copy)
                winning.removeAll()
            }
        }
        
        //vertical rows
        for i in 0...5 {
            for j in stride(from: i, to: 25, by: 5) {
                if cubeList.contains(collection[j]) {
                    winning.append(data[j])
                }
                else {
                    winning.removeAll()
                    break
                }
            }
            if winning.count == 5 {
                let copy = winning
                won.append(copy)
                winning.removeAll()
            }
        }
        
        //diagonals
        //0, 6, 12, 18, 24
        for i in stride(from: 0, to: 25, by:6) {
            if cubeList.contains(collection[i]) {
                winning.append(data[i])
            }
            else {
                winning.removeAll()
                break
            }
            if winning.count == 5 {
                let copy = winning
                won.append(copy)
                winning.removeAll()
            }
        }

        //4, 8, 12, 16, 20
        for i in stride(from: 4, to: 24, by: 4) {
            if cubeList.contains(collection[i]) {
                winning.append(data[i])
            }
            else {
                winning.removeAll()
                break
            }
            if winning.count == 5 {
                let copy = winning
                won.append(copy)
                winning.removeAll()
            }
        }
        if won.count > 0 {
            win(won)
        }
    }
    
    func win(_ answers: [[String]]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.emitWin(answers)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "iwon"), object: nil, userInfo:["answers" : answers])
    }
    
    //MARK: collection view data source
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! LetterCube
        cell.titleLabel.text = String(data[(indexPath as NSIndexPath).row])
        let row:Int = (indexPath as NSIndexPath).row/3
        let col:Int = (indexPath as NSIndexPath).row%3
        cell.index = CGPoint(x: row, y: col)
        cell.isUserInteractionEnabled = !disabled
        cell.backgroundColor = UIColor.white
        collection.append(cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collection.removeAll()
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            let w = collectionView.frame.size.width
            let h = collectionView.frame.size.height
            let d = CGFloat(sqrt(Double(data.count)))
            let ww = w/d-7
            let hh = h/d-7
            return CGSize(width: ww, height: hh)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 5
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! LetterCube
        if let index = cubeList.index(of: cell)
        {
            cubeList.remove(at: index)
            wordList.remove(at: index)
            cell.mark(false)
        }
        else {
            cubeList.append(cell)
            wordList.append(cell.titleLabel.text!)
            cell.mark(true)
        }
        self.checkForWin()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

