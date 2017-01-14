 //
//  InitialViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 2/8/16.
//  Copyright © 2016 a. All rights reserved.
//
 
//public let baseUrl = "http://test.clichesbingo.com:8900"
 public let baseUrl = "http://192.168.1.65:8900"
 
import UIKit

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

 
class InitialViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var roomCodeTextField: UITextField!
    @IBOutlet weak var createNewButton: UIButton!
    @IBOutlet weak var joinView: UIView!
    @IBOutlet weak var joinExistingButton: UIButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!

    var justLeft = false
    var username = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController!.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController!.navigationBar.shadowImage = UIImage.init()
        navigationController!.navigationBar.isTranslucent = true
        navigationController!.navigationBar.backgroundColor = UIColor.clear
        navigationController!.view.backgroundColor = UIColor.clear
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        if justLeft {
            cancelJoinTapped(self)
            justLeft = false
        }
        else {
            super.viewWillAppear(animated)
            self.navigationController?.isNavigationBarHidden = true
            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let game = appDelegate.currentGame {

                createNewGame(game, roomCode: appDelegate.roomCode! as String)

            }
        }
    }
    
    @IBAction func joinExistingGameTapped(_ sender: AnyObject) {
        usernameTextField.resignFirstResponder()
        roomCodeTextField.becomeFirstResponder()
        createNewButton.isHidden = true
        orLabel.isHidden = true
        joinView.isHidden = false
    }
    
    @IBAction func cancelJoinTapped(_ sender: AnyObject) {
        createNewButton.isHidden = false
        orLabel.isHidden = false
        joinView.isHidden = true
        roomCodeTextField.text = nil
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.roomCode = nil
        joinExistingButton .setTitle("Join existing game", for: UIControlState.disabled)
        if username.characters.count > 0 {
            joinExistingButton.isHidden = false
        }
    }
    
    @IBAction func createGameTapped(_ sender: AnyObject) {
        
        performSegue(withIdentifier: "showSelectGame", sender: self)
    }
    
    func createNewGame(_ game:Game, roomCode:String) {
        usernameTextField.resignFirstResponder()
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let url = URL(string: "\(baseUrl)/createRoom")
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        
        //yes, I need these so that the server can parse the body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
               let dictData = ["roomId" : roomCode, "words" : game.words]
        var postData:Data
        do {
            postData = try JSONSerialization.data(withJSONObject: dictData, options: JSONSerialization.WritingOptions.init(rawValue: 0))
            request.httpBody = postData
        }
        catch {
            print("error serializing json")
        }
        
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data, response, err) -> Void in
            if let error = err {
                print(error)
                let alert = UIAlertController(title: "Error connecting to server", message: "the game could not be created", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:nil))
                self!.present(alert, animated: true, completion: nil)
            }
            else if let _ = data {
                DispatchQueue.main.async(execute: { () -> Void in
                    self!.createNewButton.isHidden = true
                    self!.joinView.isHidden = false
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    self!.roomCodeTextField.text = appDelegate.roomCode! as String
                    self!.joinExistingButton.isHidden = true
                    self!.joinExistingButton.setTitle("Join your new game", for: UIControlState.disabled)
                    self!.orLabel.isHidden = true
                    self!.playButton.isEnabled = true
                })
            }
        }) 
        dataTask.resume()

    }
    
    @IBAction func unwind(_ segue:UIStoryboardSegue) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.socket?.leaveNamespace()
        justLeft = true
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let roomCode:String = roomCodeTextField.text!

        appDelegate.startPlaying(roomCode)
    }

    
    // Mark: - text field delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let isBackspace = range.length == 1 && string == ""
        
        let allowedSet = (CharacterSet.decimalDigits as NSCharacterSet).mutableCopy()
        (allowedSet as AnyObject).formUnion(with: CharacterSet.whitespaces)
        let ndRange = string.rangeOfCharacter(from: (allowedSet as AnyObject).inverted)
        let isNonDigit:Bool = ndRange?.lowerBound != ndRange?.upperBound
        
        let numReplacing:Int = string.trimmingCharacters(in: CharacterSet.whitespaces).characters.count
        
        let numExisting = (textField.text != nil) ? textField.text!.characters.count : 0
        
        if textField == roomCodeTextField {

            //can become enabled by: backspacing down to 5, typing up to 5, and pasting 5 digits
            //can become disabled by: backspacing down from 5, typing up from 5
            if isBackspace {
                if numExisting == 5 {
                    self.playButton.isEnabled = false
                    }
                else if numExisting == 6 {
                    self.playButton.isEnabled = true
                }
                return true
            }
            else if numReplacing == 0 { //just whitespace
                return false
            }
            else if isNonDigit {
                return false
            }
            else if numExisting + numReplacing == 5 {
                self.playButton.isEnabled = true
                return true
            }
            else if numExisting + numReplacing > 5 {
                return false
            }
            return true
        }
            
        else if textField == usernameTextField {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if usernameTextField.text?.characters.count > 20 {
                return false
            }
            else if (usernameTextField.text?.characters.count > 1 || string != "") {
                username = usernameTextField.text! + string
                appDelegate.currentUserName = username
                joinExistingButton.isHidden = false
                createNewButton.isHidden = false
                orLabel.isHidden = false
            }
            else {
                username = ""
                appDelegate.currentUserName = nil
                joinExistingButton.isHidden = true
                createNewButton.isHidden = true
                orLabel.isHidden = true
            }
        }
        return true
    }

    
}
