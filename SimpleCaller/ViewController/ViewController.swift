//
//  ViewController.swift
//  SimeplCaller
//
//  Created by pzdev on 22/05/21.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var RegisterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser != nil {
            let currentUser = Users.current_user()
            if currentUser == nil {
                Users.saveUserFromDB(uid: Auth.auth().currentUser!.uid)
            }
            showContacts()
        } else {
            setupElements()
        }
    }

    func setupElements() {
        UIStyles.styleFilledButton(LoginButton)
        UIStyles.styleHollowButton(RegisterButton)
    }
    
    func showContacts() {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: Constants.Storyboard.ContactsViewController) as? ContactsViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}

