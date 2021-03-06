//
//  CreateGameViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 3/15/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import MessageUI
import Contacts
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
;

class InviteViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var addEmailTextField: UITextField!
    @IBOutlet weak var addEmailButton: UIButton!
    @IBOutlet weak var sendInvitesButton: UIButton!
    @IBOutlet weak var skipCancelButton: UIButton!
    @IBOutlet weak var emailsTableView: UITableView!
    
    @IBAction func unwindToInvite(_ segue: UIStoryboardSegue) {}
    
    var gameOngoing = false
    var contacts = [CNContact]()
    var emails = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        emailsTableView.tableFooterView = UIView()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        if gameOngoing {
            self.skipCancelButton.isHidden = true
        }
        else {
            self.skipCancelButton.isHidden = false
        }
    }

    @IBAction func addEmailTapped(_ sender: AnyObject) {
        emails.append(addEmailTextField.text!)
        addEmailTextField.text = nil
        sendInvitesButton.isHidden = false
        emailsTableView.reloadData()
    }
    
    @IBAction func sendInvitesTapped(_ sender: AnyObject) {
        if let mailComposeViewController = configuredMailComposeViewController() {
            if MFMailComposeViewController.canSendMail() {
                present(mailComposeViewController, animated: true, completion: nil)
            } else {
                showSendMailErrorAlert("Check to make sure you have an email account set up on your device") //not sure if this is ever called
            }
        }
        else {
            showSendMailErrorAlert("Error identifying room.  Please re-try initiating the game")
        }
    }
    
    @IBAction func skipTapped(_ sender: AnyObject) {
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.roomCode == nil {
            return nil
        }
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        var subject = "You've been invited to play Buzzwords Bingo!"
        mailComposerVC.setToRecipients(emails)
             mailComposerVC.setSubject(subject)
        if let username = appDelegate.currentUserName {
            if let gameName = appDelegate.currentGame?.name {
                subject = "\(username) invited you to join the game \"\(gameName)\" in Buzzwords Bingo!"
                mailComposerVC.setSubject(subject)
            }
        }
        mailComposerVC.setMessageBody(subject + "<br/><br/>Your room code is: <b>\(appDelegate.roomCode!)</b><br/><br/>In <a href='http://itunes.com/apps/buzzwordsbingo'>Buzzwords Bingo</a>, hit \"Join existing game\" and copy or type <b>\(appDelegate.roomCode!)</b> into the room code field.<br/><br/><a href='http://itunes.com/apps/buzzwordsbingo'>Download the App</a>", isHTML: true)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert(_ message: String) {
        let sendMailErrorAlert = UIAlertController(title: "Could not open email", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel) { [unowned self] (UIAlertAction) -> Void in
            self.goBack()
        }
        sendMailErrorAlert.addAction(ok)
        
        present(sendMailErrorAlert, animated: true, completion: nil)
    }

    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        goBack()
    }
    
    func goBack() {
        if gameOngoing {
            _ = self.navigationController?.popViewController(animated: true)
        }
        else {
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: - text field delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text?.characters.count > 0 && isValidEmail(textField.text!) {
            addEmailButton.isEnabled = true
        }
        else {
            addEmailButton.isEnabled = false
        }
        return true
    }
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z0-9-]+"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    // MARK: - table view data source 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailCell")
        cell?.selectionStyle = UITableViewCellSelectionStyle.none
        cell?.textLabel?.textColor = kReddishBrownColor
        
        let currentEmail = emails[(indexPath as NSIndexPath).row]
        cell?.textLabel!.text = currentEmail
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            emails.remove(at: (indexPath as NSIndexPath).row)
            tableView.reloadData()
        }
    }

}
