//
//  ProviderDelegate.swift
//  SimpleCaller
//
//  Created by pzdev on 07/07/21.
//

import Foundation
import CallKit

class ProviderDelegate: NSObject, CXProviderDelegate {
    
    private let provider: CXProvider
    public var CallPayload: [String: Any?]
    public var CallState: String?
    
    override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        self.CallPayload = [String: Any?]()
        
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = NSLocalizedString("CallKit", comment: "SimpleCaller")
        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)

        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        
        return providerConfiguration
    }
    
    func providerDidReset(_ provider: CXProvider) {
    }
    
    func reportIncomingCall(payload: [String : Any?]) {
        self.CallPayload = payload
        self.CallPayload["CallUUID"] = UUID()
        let update = CXCallUpdate()
        update.hasVideo = true
        update.remoteHandle = CXHandle(type: .generic, value: self.CallPayload["fromUser"] as! String)
        provider.reportNewIncomingCall(with: self.CallPayload["CallUUID"] as! UUID, update: update, completion: {error in})
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        
        self.configureAudioSession()
        
        self.CallState = "answered"
        print(self.CallPayload)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationController = UIApplication.shared.windows.first?.rootViewController as! UINavigationController
        print(navigationController.visibleViewController!)
        if let viewController = storyboard.instantiateViewController(withIdentifier: Constants.Storyboard.CallViewController) as? CallViewController {
            viewController.CallUUID = (self.CallPayload["CallUUID"] as! UUID)
            viewController.sessionType = "join"
            viewController.sessionId = (self.CallPayload["session_id"] as! String)
            viewController.fromUsername = (self.CallPayload["fromUser"] as! String)
            navigationController.pushViewController(viewController, animated: true)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        if self.CallState != "answered" {
            let callSession = CallSession(localVideoView: nil, remoteVideoView: nil)
            let user = Users.current_user()
            callSession.DeclineCall(userId: user!.uid, sessionId: self.CallPayload["session_id"] as! String, action: {
                action.fulfill()
            })
        } else {
            action.fulfill()
        }
        
        self.CallState = nil
    }
    
    func endCall(callUUID: UUID) {
        let controller = CXCallController()
        let transaction = CXTransaction(action: CXEndCallAction(call: callUUID));controller.request(transaction,completion: { error in })
    }
    
    func configureAudioSession() {
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
            try session.setActive(true)
            try session.setMode(AVAudioSession.Mode.videoChat)
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005)
        } catch {
            print(error)
        }
    }
    
}
