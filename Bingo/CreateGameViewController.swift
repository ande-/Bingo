//
//  CreateGameViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 4/18/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class CreateGameViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    

    @IBOutlet weak var nameOfGame: UITextField!
    @IBOutlet weak var wordsTextView: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        automaticallyAdjustsScrollViewInsets = false;

    }
    
    @IBAction func defaultSelectionTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func doneTapped(_ sender: AnyObject) {
        let name = nameOfGame.text!
        let words = wordsTextView.text!
        self.saveGameWords(name, words: words)
    }
    
    func saveGameWords(_ name:String, words:String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Game")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        var preExistingGames = [NSManagedObject]()
        do {
            let results = try managedContext.fetch(fetchRequest)
            preExistingGames = results as! [NSManagedObject]
        }
        catch {
            print("could not fetch custom games \(error)")
        }
        
        if preExistingGames.count > 0 {
            let alert = UIAlertController(title: "Warning", message: "A game named \(name) already exists.  Do you want to overwrite that game with the new one?", preferredStyle: UIAlertControllerStyle.alert)
            let actionNo = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let actionYes = UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: {
                [unowned self]
                (action) in
                self.saveAndDelete(name, words: words, oldGames: preExistingGames)
            })
            alert.addAction(actionNo)
            alert.addAction(actionYes)
            present(alert, animated: true, completion: nil)
        }
        else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            let managedGame:NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Game", into: managedContext)
            managedGame.setValue(name, forKey: "name")
            managedGame.setValue(words, forKey: "words")
            
            do {
                try managedContext.save()
            }
            catch {
                print("error saving game: \(error)")
            }
            appDelegate.currentGame = Game(name: name, words: words)
            appDelegate.generateRoomCode()
            performSegue(withIdentifier: "showInvite", sender: self)
        }
    }
    
    func saveAndDelete(_ name:String, words:String, oldGames:[NSManagedObject]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        for g in oldGames {
            managedContext.delete(g)
        }
        let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: managedContext)
        
        game.setValue(name, forKey: "name")
        game.setValue(words, forKey: "words")
        do {
            try managedContext.save()
        }
        catch {
            print("error saving game: \(error)")
        }
        appDelegate.currentGame = Game(name: name, words: words)
        appDelegate.generateRoomCode()
        performSegue(withIdentifier: "showInvite", sender: self)
    }
    
    // MARK: - Text Field delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text?.characters.count > 0 {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
        return true
    }

}

