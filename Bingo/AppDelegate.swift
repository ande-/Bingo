    //
//  AppDelegate.swift
//  Bingo
//
//  Created by Andrea Houg on 2/1/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import SocketIO

    
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var currentUserName:String?
    var currentGame:Game?
    var roomCode:NSString?
    var socket:SocketIOClient?
    var sleeping: Bool = false
    var contactStore = CNContactStore()
    
    // Mark: - socket
    func startPlaying(_ roomCode: String) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.roomCode = roomCode as NSString?
        
        if socket != nil {
            socket?.joinNamespace(roomCode)
        }
        
        let url: URL = URL.init(string: "\(baseUrl)")!
        let opt1 = SocketIOClientOption.nsp("/" + roomCode);
        let opt2 = SocketIOClientOption.connectParams(["name": currentUserName!]);
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
                if name != self!.currentUserName {  //someone else joined
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
        let nc = self.window?.rootViewController as! UINavigationController

        if let ivc = nc.visibleViewController as? InitialViewController {
            ivc.performSegue(withIdentifier: "showGame", sender: self)
            UIApplication.shared.isIdleTimerDisabled = true;

        }
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
    
    func handleError(_ errorMessage:String) {
        var showingMessage = errorMessage; // TODO: make this empty string, showing all messages for debugging only
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
        else if (errorMessage.contains("The operation couldn’t be completed. Socket is not connected")) {
            if (sleeping) {
                sleeping = false
                // eat it
                socket?.reconnect() // TODO: will this be the same namespace?
                return
            }
        }
        let alert = UIAlertController(title: "Error", message: showingMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        let vc = self.window?.rootViewController
        vc?.present(alert, animated: true, completion: nil)
    }
    
    func emitWin(_ answers: [[String]]) {
        self.socket!.emit("win", currentUserName!, answers)
    }
    
    func endGame() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentGame = nil
        appDelegate.roomCode = nil
        socket?.leaveNamespace()
        
        let nc = self.window?.rootViewController as! UINavigationController

        if let ivc = nc.viewControllers.first as? InitialViewController {
            ivc.cancelJoinTapped(self);
        }
    }
    
    // Mark: - app delegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window?.tintColor = kReddishBrownColor

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        if (socket?.status == SocketIOClientStatus.connected && currentGame != nil) {
            sleeping = true
            socket?.emit("sleeping", currentUserName!)
        }

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if (currentGame != nil) {
            socket?.reconnect() //  this doesn't seem to be working properly TODO: will this be the same namespace?
        }

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        NotificationCenter.default.removeObserver(self)

        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named [identifier] in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Bingo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func generateRoomCode() {
        var code = ""
        for _ in 1...5 {
            code += String(arc4random_uniform(9))
        }
        roomCode = code as NSString?
    }

}

