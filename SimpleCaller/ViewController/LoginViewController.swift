//
//  LoginViewController.swift
//  SimeplCaller
//
//  Created by pzdev on 22/05/21.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordField: UITextField!
    
    @IBOutlet weak var ErrorLabel: UILabel!
    @IBOutlet weak var LoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupElements()
    }
    
    func setupElements() {
        
        ErrorLabel.alpha = 0
        
        UIStyles.styleTextField(EmailTextField)
        UIStyles.styleTextField(PasswordField)
        PasswordField.isSecureTextEntry = true
        UIStyles.styleFilledButton(LoginButton)
    }
    
    func showError(message: String) {
        ErrorLabel.text = message
        ErrorLabel.alpha = 1
    }
    
    func validateFields() -> String? {
        let Email = EmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let Password = PasswordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if (Email == "" || Password == "") {
            return  "Please fill in all fields"
        }
        
        return nil
    }
    
    func transitionToContacts() {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: Constants.Storyboard.ContactsViewController) as? ContactsViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func transitionToCall() {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: Constants.Storyboard.CallViewController) as? CallViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func BackTapped(_ sender: Any) {
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func LoginTapped(_ sender: Any) {
        
        self.view.endEditing(true)
        let error = validateFields()
        
        if error != nil {
            showError(message: error!)
        } else {
            let Email = EmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let Password = PasswordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            Auth.auth().signIn(withEmail: Email, password: Password) { (result, err) in
                if err != nil {
                    self.showError(message: err!.localizedDescription)
                } else {
                    //self.transitionToContacts()
                    
                    let uid = Auth.auth().currentUser?.uid
                    Users.saveUserFromDB(uid: uid!)
                    self.transitionToContacts()
                }
            }
        }
    }
    
}
