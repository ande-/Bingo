//
//  ContactsViewController.swift
//  Bingo
//
//  Created by Andrea Houg on 9/2/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit
import Contacts

class ContactEmail {
    var name: String?
    var email: String
    init(name:String?, email:String) {
        self.name = name
        self.email = email
    }
}

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var contacts = [ContactEmail]()
    var selectedEmail: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.separatorColor = kBrownColor
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        automaticallyAdjustsScrollViewInsets = false;
        
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = kReddishBrownColor
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let s = searchBar.text {
            enable(s);
        }
    }

    func enable(_ term: String) {
        requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let predicate = CNContact.predicateForContacts(matchingName: term)
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
                var contacts = [CNContact]()
                var message: String!
                
                let appDel = UIApplication.shared.delegate as! AppDelegate;
                
                let contactsStore = appDel.contactStore
                do {
                    contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                    
                    if contacts.count == 0 {
                        message = "No contacts were found matching the given name."
                    }
                }
                catch {
                    message = "Unable to fetch contacts."
                }
                
                
                if message != nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        print(message)
                    })
                }
                else {
                    for contact in contacts {
                        let nameString = "\(contact.givenName) \(contact.familyName)"
                        for emailAddress in contact.emailAddresses {
                            let emailString = emailAddress.value as String
                            let newContactEmail = ContactEmail(name: nameString, email: emailString)
                            self.contacts.append(newContactEmail)
                        }
                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                    })
                }
            }
        }

    }
    
    
    func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        let appDel = UIApplication.shared.delegate as! AppDelegate;
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
            
        case .denied, .notDetermined:
            appDel.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        DispatchQueue.main.async(execute: { () -> Void in
                            print("denied contact access");
                        })
                    }
                }
            })
            
        default:
            completionHandler(false)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.selectionStyle = UITableViewCellSelectionStyle.none

        let currentContact = contacts[(indexPath as NSIndexPath).row]
        
        cell?.textLabel!.text = currentContact.name

        // Set the contact's home email address.
        cell?.detailTextLabel!.text = currentContact.email
        
        return cell!
    }
    
    @IBAction func exitTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindToInvite", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact:ContactEmail = contacts[(indexPath as NSIndexPath).row];
        selectedEmail = contact.email
        performSegue(withIdentifier: "unwindToInvite", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dvc: InviteViewController = segue.destination as?InviteViewController {
            if (selectedEmail != nil) {
                dvc.emails.append(selectedEmail!)
                dvc.sendInvitesButton.isHidden = false
                dvc.emailsTableView.reloadData()
            }
        }
    }

}
