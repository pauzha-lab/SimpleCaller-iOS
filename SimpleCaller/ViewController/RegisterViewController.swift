//
//  RegisterViewController.swift
//  SimeplCaller
//
//  Created by pzdev on 22/05/21.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController {
    
    
    @IBOutlet weak var UsernameTextField: UITextField!
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    
    @IBOutlet weak var ErrorLabel: UILabel!
    
    @IBOutlet weak var RegisterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupElements()
    }
    
    func setupElements() {
        
        ErrorLabel.alpha = 0
        
        UIStyles.styleTextField(UsernameTextField)
        UIStyles.styleTextField(EmailTextField)
        UIStyles.styleTextField(PasswordTextField)
        UIStyles.styleTextField(PasswordTextField)
        PasswordTextField.isSecureTextEntry = true
        UIStyles.styleFilledButton(RegisterButton)
    }
    
    func validateFields() -> String? {
        
        if UsernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            EmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            PasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "Please fill in all fields"
        }
        
        let cleanedPassword = PasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ElmValidator.isPasswordValid(cleanedPassword) == false {
            return "Please make sure your password is at least 6 characters, contains a special charater and a number"
        }
        
        return nil
    }

    func showError(_ message: String) {
        ErrorLabel.text = message
        ErrorLabel.alpha = 1
    }
    
    func transitionToContacts() {
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
    
    @IBAction func RegisterTapped(_ sender: Any) {
        
        let error = validateFields()
        
        if error != nil {
            showError(error!)
        } else {
            let email = EmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = PasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let username = UsernameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            // create user
            Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
                if err != nil {
                    //let error_code = err.localizedDescription
                    self.showError("Error creating user")
                } else {
                    Users.register_user(username, uid: result!.user.uid)
                    self.transitionToContacts()
                }
            }
        }
    }
}
