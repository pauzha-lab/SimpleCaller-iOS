//
//  CallViewController.swift
//  SimeplCaller
//
//  Created by pzdev on 24/06/21.
//

import UIKit
import WebRTC

class CallViewController: UIViewController {
    
    @IBOutlet weak var LocalVideoView: RTCMTLVideoView!
    @IBOutlet weak var RemoteVideoView: RTCMTLVideoView!
    
    @IBOutlet weak var MessageLabel: UILabel!
    @IBOutlet weak var MuteButton: UIButton!
    @IBOutlet weak var StopButton: UIButton!
    @IBOutlet weak var ToggleVideoButton: UIButton!
    @IBOutlet weak var ToggleCamera: UIButton!
    
    private var mediaCapturer: MediaCapturer!
    
    var sessionType: String?
    var toUsername: String?
    var toUserId: String?
    var fromUsername: String?
    var fromUserId: String?
    var sessionId: String?
    var CallUUID: UUID?
    
    private var user: User?
    private var callSession: CallSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUi()
        
        self.RemoteVideoView.contentMode = .scaleAspectFit
        self.LocalVideoView.contentMode = .scaleAspectFit
        // Do any additional setup after loading the view.
        self.view.sendSubviewToBack(self.RemoteVideoView)
        
        //let renderFrame = AVMakeRect(aspectRatio: CGSize(width: <#T##CGFloat#>, height: <#T##CGFloat#>), insideRect: self.view.bounds)
        //self.RemoteVideoView.frame = renderFrame
        
        
        self.UiVisibleState(hidden: true)
        
        self.checkDevicePermissions()
        
    }
    
    func setupUi() {
        if #available(iOS 13.0, *) {
            self.StopButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        self.StopButton.layer.cornerRadius = self.StopButton.frame.width / 2
        self.StopButton.layer.masksToBounds = true
        self.StopButton.tintColor = UIColor.white
        

        self.MuteButton.layer.cornerRadius = self.StopButton.frame.width / 2
        self.MuteButton.layer.masksToBounds = true
        self.setMicEnabledImage()
        

        self.ToggleVideoButton.layer.cornerRadius = self.StopButton.frame.width / 2
        self.ToggleVideoButton.layer.masksToBounds = true
        self.setCameraEnabledImage()
        
        if #available(iOS 13.0, *) {
            self.ToggleCamera.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        self.ToggleCamera.layer.cornerRadius = self.StopButton.frame.width / 2
        self.ToggleCamera.layer.masksToBounds = true
        self.ToggleCamera.tintColor = UIColor.black
        self.ToggleCamera.isHidden = true
    }
    
    
    func initCallSession() {
        
        self.user = Users.current_user()
        
        self.callSession = CallSession.init(localVideoView: self.LocalVideoView, remoteVideoView: self.RemoteVideoView)
        self.callSession?.events.listenTo(eventName: "connection_state", action:  self.sessionEventsHandler)
        
        if self.sessionType == "create" {
            self.callSession?.InitiateCall(ClientId: self.user!.uid, remoteUserId: toUserId!)
        } else if self.sessionType == "join" {
            self.callSession?.JoinCall(ClientId: self.user!.uid, sessionId: sessionId!)
        } else {
            print("unknow sessionType -> \(String(describing: self.sessionType))")
        }
    }
    

    @IBAction func StopCall(_ sender: Any) {
        self.endCall()
    }
    
    @IBAction func ToggleMicrophone(_ sender: Any) {
        self.callSession?.toggleMicrophone()
        
        if self.callSession?.audioEnabled == true {
            self.setMicEnabledImage()
        } else {
            self.setMicDisabledImage()
        }
    }
    
    @IBAction func ToggleVideo(_ sender: Any) {
        self.callSession?.toggleCamera()
        if self.callSession?.videoEnabled == true {
            self.setCameraEnabledImage()
        } else {
            self.setCameraDisabledImage()
        }
    }
    
    @IBAction func ChangeCamera(_ sender: Any) {
            DispatchQueue.main.async {
                do {
                    try self.callSession?.toggleCamerafacing()
                    
                } catch let err {
                    print(err)
                }
            }
            
        
    }
    
    func setCameraDisabledImage() {
        if #available(iOS 13.0, *) {
            self.ToggleVideoButton.setImage(UIImage(systemName: "video.slash.fill"), for: .normal)
            self.ToggleVideoButton.tintColor = UIColor.red
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setCameraEnabledImage() {
        if #available(iOS 13.0, *) {
            self.ToggleVideoButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
            self.ToggleVideoButton.tintColor = UIColor.black
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setMicEnabledImage() {
        if #available(iOS 13.0, *) {
            self.MuteButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            self.MuteButton.tintColor = UIColor.black
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setMicDisabledImage() {
        if #available(iOS 13.0, *) {
            self.MuteButton.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
            self.MuteButton.tintColor = UIColor.red
        } else {
            // Fallback on earlier versions
        }
    }
    
    func openContacts() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let contactsView = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.ContactsViewController) as! ContactsViewController
        navigationController?.pushViewController(contactsView, animated: true)
    }
    
    func checkDevicePermissions() {
        // Camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized, AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            self.initCallSession()
        } else {
            self.MessageLabel.text = "Requires video and audio permissions"
        }
    }
    
    func UiVisibleState(hidden: Bool) {
        self.MuteButton.isHidden = hidden
        self.ToggleVideoButton.isHidden = hidden
        //self.ToggleCamera.isHidden = hidden
        self.LocalVideoView.isHidden = hidden
        self.RemoteVideoView.isHidden = hidden
    }
    
    func endCall() {
        if self.callSession != nil {
            self.callSession?.EndCall(action: {
                if self.CallUUID != nil {
                    guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
                        print("appdelegate is missing")
                        return
                    }
                    appdelegate.callProvider.endCall(callUUID: self.CallUUID!)
                }
                self.callSession?.close()
                self.openContacts()
            })
        } else {
            self.openContacts()
        }
    }
    
    func sessionEventsHandler(information: Any?) {
        let connection_state = information as! String
        
        switch connection_state {
            case "initializing":
                DispatchQueue.main.async {
                    self.MessageLabel.text = "Connecting Call"
                }
                
            case "connected":
                DispatchQueue.main.async {
                    self.MessageLabel.isHidden = true
                    self.MessageLabel.text = "User connected"
                    self.UiVisibleState(hidden: false)
                }
               
            case "ended":
                DispatchQueue.main.async {
                    self.UiVisibleState(hidden: true)
                    self.MessageLabel.isHidden = false
                    self.MessageLabel.text = "Call Ended"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.endCall()
                }
            case "declined":
                DispatchQueue.main.async {
                    self.MessageLabel.text = "Call Declined"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.endCall()
                }
            case "not_reachable":
                DispatchQueue.main.async {
                    self.MessageLabel.text = "User not reachable"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.endCall()
                    
                }
            case "SOCKET_TIMEOUT":
                DispatchQueue.main.async {
                    self.MessageLabel.text = "Cannot connect to server"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.endCall()
                }
        default:
            print("unknown connection_state -> \(connection_state)")
        }
    }

}
