//
//  ContactsViewController.swift
//  SimeplCaller
//
//  Created by pzdev on 22/05/21.
//

import UIKit
import Firebase

class ContactsViewController: UIViewController {

    @IBOutlet weak var TableView: UITableView!
    private var UsersList = [String: String]()
    @IBOutlet weak var LogoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        TableView.delegate = self
        TableView.dataSource = self
        
        self.getUsers()
        self.getPermissions()
        
    }
    
    func getPermissions() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (isGranted: Bool) in
        })
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (isGranted: Bool) in
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func LogoutAction(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            navigationController?.pushViewController((self.storyboard?.instantiateViewController(withIdentifier: "MainView"))!, animated: true)
        } catch let err {
            print(err)
        }
        
        
    }
    
    func getUsers() {
        let current_uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("users").getData { (error, snapshot) in
            if let error = error {
                print("Error getting data \(error)")
            }
            else if snapshot.exists() {
                //print("Got data \(snapshot.value!)")
                let users = snapshot.value as! NSDictionary
                for (_id, _user) in users {
                    let user = _user as! NSDictionary
                    let username = user["Username"] as! String
                    let user_id = _id as! String
                    if current_uid == user_id {
                        continue
                    }
                    self.UsersList[user_id] = username
                }
                DispatchQueue.main.async {
                    self.TableView.reloadData()
                }
            }
            else {
                print("No data available")
            }
        }
    }

}

extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userId = Array(self.UsersList.keys)[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let callView = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.CallViewController) as! CallViewController
        callView.toUserId = userId
        callView.toUsername = UsersList[userId]
        callView.sessionType = "create"
        navigationController?.pushViewController(callView, animated: true)
        print("you tapped me \(UsersList[userId]!)")
    }
}

extension ContactsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.UsersList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let userId = Array(self.UsersList.keys)[indexPath.row]
        cell.textLabel?.text = UsersList[userId]
        cell.selectionStyle = UITableViewCell.SelectionStyle.blue
        var phoneImg = UIImage(named: "phone-call")
        phoneImg = phoneImg?.scaleImage(toSize: CGSize(width: 10, height: 10))
        cell.imageView?.image = phoneImg
        return cell
    }
}
