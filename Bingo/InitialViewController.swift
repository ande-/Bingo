 //
//  InitialViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 2/8/16.
//  Copyright © 2016 a. All rights reserved.
//
 
public let baseUrl = "http://test.clichesbingo.com:8900"
//public let baseUrl = "http://localhost:8900"
 
import UIKit
import SocketIO
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
    var socket:SocketIOClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(emitWin(_:)), name: NSNotification.Name(rawValue: "iwon"), object: nil)
        
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
    
    func generateRoomCode() {
        
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
                    self!.playButton.isHidden = false
                })
            }
        }) 
        dataTask.resume()

    }
    
    @IBAction func unwind(_ segue:UIStoryboardSegue) {
        socket?.leaveNamespace()
        justLeft = true
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        let roomCode:String = roomCodeTextField.text!
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.roomCode = roomCode as NSString?
        
        if socket != nil {
            socket?.joinNamespace(roomCode)
        }
        
        let url: URL = URL.init(string: "\(baseUrl)")!
        let opt1 = SocketIOClientOption.nsp("/" + roomCode);
        let opt2 = SocketIOClientOption.connectParams(["name": username]);
        let config: SocketIOClientConfiguration = [opt1, opt2];
        socket = SocketIOClient(socketURL: url, config: config);

    
        //socket = SocketIOClient(socketURL:url, options:[SocketIOClientOption.nsp("/" + roomCode), SocketIOClientOption.connectParams(["name": username]) ])

        addHandlers()
        socket?.connect()
    }
    
    func addHandlers() {	
        socket!.onAny {print("Got event: \($0.event), with items: \($0.items)")}
        
        socket?.on("error") {[weak self] data, ack in
            if let message = data[0] as? String {
                self?.handleError(message)
            }
        }
        
        socket!.on("disconnect") {[weak self] data, ack in
            self?.socket = nil
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.roomCode = nil
        }
        
        socket!.on("playerLeft") {[weak self] data, ack in
            if let name = data[0] as? String {
                self?.handleLeave(name)
            }
        }
        
        socket!.on("playerJoined") {[weak self] data, ack in
            if let name = data[0] as? String {
                if name != self!.username {  //someone else joined
                    self?.handleJoin(name)
                }
                else if let words = data[1] as? String {
                    self?.handleMeJoin(words)
                }
            }
        }
        
        socket!.on("win") {[weak self] data, ack in
            if let name = data[0] as? String, let typeDict = data[1] as? [[String]] {
                self?.handleWin(name, answers: typeDict)
            }
        }
    }
    
    func handleLeave(_ name:String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "playerLeft"), object: nil, userInfo: ["name" : name])
    }
    
    func handleMeJoin(_ words:String) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if (appDelegate?.currentGame == nil) {
            appDelegate?.currentGame = Game(name: "Remote Game", words: words)
        }
        performSegue(withIdentifier: "showGame", sender: self)
    }
    
    func handleJoin(_ name:String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "playerJoined"), object: nil, userInfo: ["name" : name])
    }
    
    func handleWin(_ name:String, answers:[[String]]) {
        var message:String = ""
        for i in 0 ..< answers.count {
            if answers.count > 1 {
                message.append("\(i + 1). ")
            }
            message.append(answers[i].joined(separator: ", "))
            if answers.count > 1 && answers.count > i {
                message.append("\n")
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "win"), object: nil, userInfo: ["name" : name, "answers" : message])
    }
    
    func emitWin(_ notification: Notification) {
        if let userInfo = (notification as NSNotification).userInfo as? Dictionary<String, [[String]]> {
            if let answers = userInfo["answers"] as [[String]]? {
                self.socket!.emit("win", username, answers)
            }
        }
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
                    self.playButton.isHidden = true
                    }
                else if numExisting == 6 {
                    self.playButton.isHidden = false
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
                self.playButton.isHidden = false
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
                appDelegate.currentUserName = username as NSString?
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleError(_ errorMessage:String) {
        var showingMessage = ""
        if (errorMessage.contains("Invalid namespace")) {
            showingMessage = "The room does not exists. Make sure the game is still in progress and you entered the correct room code"
        }
        else if (errorMessage.contains("Could not connect to the server")) {
            showingMessage = "Could not connect to the server"
            socket?.disconnect()
        }
        else if (errorMessage.contains("Session ID unknown")) {
            showingMessage = "Improper disconnect, I think"
        }
        let alert = UIAlertController(title: "Error", message: showingMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.navigationController?.popToRootViewController(animated: true)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func endGame() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentGame = nil
        appDelegate.roomCode = nil
        socket?.leaveNamespace()
        cancelJoinTapped(self)
    }
    
}
