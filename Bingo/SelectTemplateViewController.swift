//
//  SelectTemplateViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 4/18/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import CoreData

class SelectTemplateViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var userGames = [Game]()
    var systemGames = [Game]()
    var isUser:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.separatorColor = kBrownColor
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        userGames = loadUserGames()
        systemGames = loadSystemGames()
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        tableView.reloadData()

    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        if sender.selectedSegmentIndex == 0 {
            isUser = true
        }
        else if sender.selectedSegmentIndex == 1 {
            isUser = false
        }
        tableView.reloadData()
    }
    
    func loadUserGames() -> [Game] {
        var games = [Game]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Game")
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            let managedResults = results as! [NSManagedObject]
            for m in managedResults {
                games.append(Game(name: m.value(forKey: "name") as! String, words: m.value(forKey: "words") as! String))
            }
            games.sort(by: { $0.name < $1.name })  //sort alphabetically for now, eventually want to sort by most recently used
        }
        catch {
            print("could not fetch custom games \(error)")
        }
        
        if games.count == 0 {
            segmentedControl.selectedSegmentIndex = 1
            isUser = false
        }
        return games
    }
    
    func loadSystemGames() -> [Game] {
        let classic = Game(name:"Classic", words: "opposites attract, when life gives you lemons, push the envelope, money doesn't grow on trees, read between the lines, woke up on the wrong side of the bed, better half, broken record, dog eat dog, greek to me, foot in mouth, it's a small world, jump the gun, learn the ropes, you only live once, when it rains it pours, tip of your tongue, spitting image, spinning your wheels, out on a limb, break the ice, killing time, light at the end of the tunnel, it is what it is")
        
        let corporate = Game(name:"Corporate", words: "synergy, leverage, strategic, partnership, DNA, mobile, global, local, paradigm, actionable, bandwidth, pipeline, culture, value-added, scalable, user experience, integrated, thought leader, X as a service, internet of things, reach out to, take this offline, touch base, ping me")
        
        let politics = Game(name:"Politics", words:"the american people, career politician, super PAC, grass-roots, middle class, veterans, top one percent, hard-working, family values, crossroads, the economy, big government, boots on the ground, right/left wing, strong leader, tax cut, radical, corrupt, terrorist, game changers, war on X, my friends, voters, my competitor")
        
        return [classic, corporate, politics]
    }
    
    //MARK: table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isUser {
            return userGames.count
        }
        else {
            return systemGames.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var game:Game
        if isUser {
            game = userGames[(indexPath as NSIndexPath).row]
        }
        else {
            game = systemGames[(indexPath as NSIndexPath).row]
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameCell") ?? TemplateTableViewCell()
        cell.textLabel?.text = game.name
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    //MARK: table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var game:Game
        if isUser {
            game = userGames[(indexPath as NSIndexPath).row]
        }
        else {
            game = systemGames[(indexPath as NSIndexPath).row]
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentGame = game
        appDelegate.generateRoomCode()
        performSegue(withIdentifier: "showInvite", sender: self)
    }
}