//
//  CallSession.swift
//  SimeplCaller
//
//  Created by pzdev on 27/06/21.
//

import Foundation
import SwiftyJSON

public enum SessionError : Error {
    case DEVICE_NOT_LOADED
    case SEND_TRANSPORT_NOT_CREATED
    case RECV_TRANSPORT_NOT_CREATED
    case DEVICE_CANNOT_PRODUCE_VIDEO
    case DEVICE_CANNOT_PRODUCE_AUDIO
    case PRODUCER_NOT_FOUND
    case CONSUMER_NOT_FOUND
    case ACTION_ERROR
}

class CallSession: NSObject {
    
    private var userId: String?
    public var peerId: String?
    public var sessionId: String?
    
    private var localStream: RTCMediaStream?
    private var remoteStream: RTCMediaStream?
    
    private var localVideoView: RTCMTLVideoView?
    private var remoteVideoView: RTCMTLVideoView?
    
    public let events = EventManager()
    private let socket: EchoSocket
    private let device: MediasoupDevice
    private let mediaCapturer: MediaCapturer
    private var producers: [String : Producer]
    private var consumers: [String : Consumer]
    
    private var sendTransport: SendTransport?
    private var recvTransport: RecvTransport?
    private var sendTransportHandler: SendTransportHandler?
    private var recvTransportHandler: RecvTransportHandler?
    
    private var producerHandler: ProducerHandler?
    private var consumerHandler: ConsumerHandler?
    
    public var connection_state: String = "not_connected"
    public var connected: Bool = false
    
    public var camera_facing = "front"
    public var audioEnabled = true
    public var videoEnabled = true
    
    private var NETWORK_ATTEMPTS: Int8 = 0

    private var SocketQueue = [String: (message: JSON) -> Void]()
    
    init(localVideoView: RTCMTLVideoView?, remoteVideoView: RTCMTLVideoView?) {
        

        self.localVideoView = localVideoView
        self.remoteVideoView = remoteVideoView
        
        Mediasoupclient.initialize()
        print("initializeMediasoup() client initialized")
        
        self.socket = EchoSocket(wsURI: Constants.Socket.URL)
        
        
        self.mediaCapturer = MediaCapturer.shared
        self.device = MediasoupDevice()
        self.producers = [String : Producer]()
        self.consumers = [String : Consumer]()
        self.connected = false
        
        super.init()
        
        
        self.socket.connect()
        self.socket.events.listenTo(eventName: "message", action: self.HandleSocketMessage)
        
    }
    
    func HandleSocketMessage(information:Any?) {
        print("HandleSocketMessage()")
        let JSONmessage = information as! String
        let data: Data = JSONmessage.data(using: .utf8)!
        let jsonMsg = JSON.init(data)
        self.HandleActions(message: jsonMsg)
    }
    
    private func HandleActions(message: JSON) {
        let action = message["action"].stringValue
        
        print("Action -> \(action)")
        
        do {
            switch action {
            
            case "router-rtp-capabilities":
                self.HandleRouterRtpCapabilitiesRequest(message: message)
            case "create-transport":
                self.HandleCreateTransportRequest(message: message)
            case "connect-transport":
                //self.HandleConnectTransportRequest(message: message)
                break
            case "produce":
                self.HandleProduceRequest(message: message)
            //case "produce-data":
            //    self.HandleProduceDataRequest()
            case "create-consumer":
                self.HandleCreateConsumer(message: message)
            case "create-data-consumer":
                self.HandleCreateDataConsumer()
            case "create-consumers":
                self.HandleCreateConsumers(message: message)
            case "new-consumer":
                try self.HandleNewConsumer(message: message)
            case "new-data-consmuer":
                self.HandleNewDataConsumer()
            case "call-ended":
                self.HandleCallEnded()
            case "call-declined":
                self.HandleDeclined()
            case "call-not-reachable":
                self.HandleCallNotReachable()
            case "error-stat":
                self.HandleErrorState(message: message)
            default:
                print("HandleActions() unknow action \(action)")
            }
        } catch {
            print("Error HandleActions()")
        }
    }
    
    private func setConnectionState(state: String) {
        self.connection_state = state
        self.events.trigger(eventName: "connection_state", information: state)
    }
    
    func HandleCallNotReachable() {
        self.setConnectionState(state: "not_reachable")
    }
    
    func HandleCallCanceled() {
        self.setConnectionState(state: "cancled")
    }
    
    func HandleErrorState(message: JSON) {
        let error = message["error"].stringValue
        switch error {
        case "user already active":
            self.setConnectionState(state: "user-inuse")
        case "session found":
            self.setConnectionState(state: "session-notfound")
        default:
            print("Unknow ERROR => \(error)")
        }
    }
    
    func InitiateCall(ClientId: String, remoteUserId: String) {
        print("InitiateCall()")
        
        print("socket connected -> \(self.socket.isConnected)")
        if (self.socket.isConnected) {
            self.userId = ClientId
            
            self.socket.send(message: JSON(
                [
                    "action": "create-call",
                    "requestFrom": ClientId,
                    "requestTo": remoteUserId
                ]
            ))
        
            self.setConnectionState(state: "initializing")
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.NETWORK_ATTEMPTS >= Constants.Socket.TIMEOUT {
                    self.setConnectionState(state: "SOCKET_TIMEOUT")
                    return
                }
                self.NETWORK_ATTEMPTS += 1
                self.InitiateCall(ClientId: ClientId, remoteUserId: remoteUserId)
            }
        }
    }
    
    func JoinCall(ClientId: String, sessionId: String) {
        print("JoinCall()")
        
        if (self.socket.isConnected) {
            self.userId = ClientId
            
            self.socket.send(message: JSON(
                [
                    "action": "join-call",
                    "requestFrom": ClientId,
                    "sessionId": sessionId
                ]
            ))
        
            self.setConnectionState(state: "initializing")
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.NETWORK_ATTEMPTS >= Constants.Socket.TIMEOUT {
                    self.setConnectionState(state: "SOCKET_TIMEOUT")
                    return
                }
                self.NETWORK_ATTEMPTS += 1
                self.JoinCall(ClientId: ClientId, sessionId: sessionId)
            }
        }
    }
    
    func getLocalMediaStream() throws {
        
    }
    
    private func getProducersByKind(kind: String) throws -> Producer {
        for producer in self.producers.values {
            if producer.getKind() == kind {
                return producer
            }
        }
        
        throw SessionError.PRODUCER_NOT_FOUND
    }
    
    func HandleRouterRtpCapabilitiesRequest(message: JSON) {
        let routerRtpCapabilities: JSON  = message["routerRtpCapabilities"]
        self.sessionId = message["sessionId"].stringValue
        self.peerId = message["peerId"].stringValue
        
        device.load(routerRtpCapabilities.description)
        
        self.createTransport(type: "produce")
        self.createTransport(type: "consume")
    }
    
   
    func createTransport(type: String) {
        
        let _msg: JSON = [
            "action": "create-transport",
            "sessionId": self.sessionId!,
            "peerId": self.peerId!,
            "type": type
        ]
        
        self.socket.send(message: _msg)
        
    }
    
    func HandleCreateTransportRequest(message: JSON) {
        
        let transport_type = message["type"].stringValue
        let id = message["id"].stringValue
        let iceParameters: JSON = message["iceParameters"]
        let iceCandidatesArray: JSON = message["iceCandidates"]
        let dtlsParameters: JSON = message["dtlsParameters"]
        
        switch transport_type {
            case "produce":
                self.sendTransportHandler = SendTransportHandler.init(parent: self)
                self.sendTransportHandler!.delegate = self.sendTransportHandler!
                self.sendTransport = self.device.createSendTransport(
                    self.sendTransportHandler!.delegate!,
                    id: id,
                    iceParameters: iceParameters.description,
                    iceCandidates: iceCandidatesArray.description,
                    dtlsParameters: dtlsParameters.description
                )
                do {
                    try self.getMediaStream()
                } catch let error {
                    print(error)
                }
                
                break
            case "consume":
                self.recvTransportHandler = RecvTransportHandler.init(parent: self)
                self.recvTransportHandler!.delegate = self.recvTransportHandler!
                self.recvTransport = self.device.createRecvTransport(
                    self.recvTransportHandler!.delegate!,
                    id: id,
                    iceParameters: iceParameters.description,
                    iceCandidates: iceCandidatesArray.description,
                    dtlsParameters: dtlsParameters.description
                )
                // Play consumers that have been stored
                //for consumerInfo in self.consumersInfo {
                //    self.consumeTrack(consumerInfo: consumerInfo)
                //}
                let _msg: JSON = [
                    "action": "get-producers",
                    "sessionId": self.sessionId!,
                    "peerId": self.peerId!
                ]
                self.socket.send(message: _msg)
            break
        default:
            print("HandleCreateTransportRequest() invalid direction " + transport_type)
        }
        
    }

    
    func getMediaStream() throws {
        
        if self.sendTransport == nil {
            throw SessionError.SEND_TRANSPORT_NOT_CREATED
        }
        
        
        if !self.device.canProduce("video") {
            throw SessionError.DEVICE_CANNOT_PRODUCE_VIDEO
        }
        
        if !self.device.canProduce("audio") {
            throw SessionError.DEVICE_CANNOT_PRODUCE_AUDIO
        }
        
        do {
            let videoTrack = try self.mediaCapturer.createVideoTrack(videoView: self.localVideoView!, facing: "front")
            let audioTrack = self.mediaCapturer.createAudioTrack()
            
            
            let codecOptions: JSON = [
                "videoGoogleStartBitrate" : 1000
            ]
            
            var encodings: Array = Array<RTCRtpEncodingParameters>.init()
            encodings.append(RTCUtils.genRtpEncodingParameters(true, maxBitrateBps: 500000, minBitrateBps: 0, maxFramerate: 60, numTemporalLayers: 0, scaleResolutionDownBy: 0))
            encodings.append(RTCUtils.genRtpEncodingParameters(true, maxBitrateBps: 1000000, minBitrateBps: 0, maxFramerate: 60, numTemporalLayers: 0, scaleResolutionDownBy: 0))
            encodings.append(RTCUtils.genRtpEncodingParameters(true, maxBitrateBps: 1500000, minBitrateBps: 0, maxFramerate: 60, numTemporalLayers: 0, scaleResolutionDownBy: 0))
            
            self.createProducer(track: videoTrack, codecOptions: codecOptions.description, encodings: nil)
            self.createProducer(track: audioTrack, codecOptions: nil, encodings: nil)
        } catch {
            print("failed to create video and audio track")
        }
        
    }
    
    func createProducer(track: RTCMediaStreamTrack, codecOptions: String?, encodings: Array<RTCRtpEncodingParameters>?) {
        self.producerHandler = ProducerHandler.init()
        self.producerHandler!.delegate = self.producerHandler!
                
        let kindProducer: Producer = self.sendTransport!.produce(self.producerHandler!.delegate!, track: track, encodings: encodings, codecOptions: codecOptions)
        self.producers[kindProducer.getId()] = kindProducer
        
        print("createProducer() created id =" + kindProducer.getId() + " kind =" + kindProducer.getKind())
    }
    

    func getDataStream() {
    
    }
    
    
    func HandleCreateDataConsumer() {
        
    }

    
    func HandleCreateConsumer(message: JSON) {
        print("HandleCreateConsumer()")
        
        let producerId = message["producerId"].stringValue
        let producer_peerId = message["producerPeerId"].stringValue
        let transportId = self.recvTransport?.getId()
        
        let _msg: JSON = [
            "action": "consume",
            "sessionId": self.sessionId!,
            "producerId": producerId,
            "peerId": self.peerId!,
            "transportId": transportId!,
            "producerPeerId": producer_peerId
        ]
        
        self.socket.send(message: _msg)
    }
    
    func HandleCreateConsumers(message: JSON) {
        print("HandleNewConsumers() *********")
        
        let producer_peers = message["producerList"]
        
        print(producer_peers)
        
        let transportId = self.recvTransport?.getId()
        
        for (producer_peerId, producers) in producer_peers {
            
            print("producing peer ID - > \(producer_peerId)")
            
            for (_, producer) in producers {
                
                let producer_kind = producer["kind"].stringValue
                let producerId = producer["id"].stringValue
                
                switch producer_kind {
                    case "data":
                        break
                    case "media":
                        let _msg: JSON = [
                            "action": "consume",
                            "sessionId": self.sessionId!,
                            "peerId": self.peerId!,
                            "transportId": transportId!,
                            "producerId": producerId,
                            "producerPeerId": producer_peerId
                        ]
                    
                        self.socket.send(message: _msg)
                    default:
                        print("HandleCreateConsumers() ERROR unknow kind -> \(producer_kind)")
                }
                
            }
        }
    }
    
    func HandleNewConsumer(message: JSON) throws {
        
        print("HandleNewConsumer()")
        
        if self.recvTransport == nil {
            throw SessionError.RECV_TRANSPORT_NOT_CREATED
        }
        
        let kind: String = message["kind"].stringValue
        let consumeId: String = message["id"].stringValue
        let producerId: String = message["producerId"].stringValue
        let rtpParameters: JSON = message["rtpParameters"]
        
        //print("HandleNewConsumer() rtpParameters " + rtpParameters.description)
        
        self.consumerHandler = ConsumerHandler.init()
        self.consumerHandler!.delegate = self.consumerHandler
        
        let kindConsumer: Consumer = self.recvTransport!.consume(self.consumerHandler!.delegate!, id: consumeId, producerId: producerId, kind: kind, rtpParameters: rtpParameters.description)
        self.consumers[kindConsumer.getId()] = kindConsumer
        
        if kindConsumer.getKind() == "video" {
            let videoTrack: RTCVideoTrack = kindConsumer.getTrack() as! RTCVideoTrack
            videoTrack.isEnabled = true
            videoTrack.add(self.remoteVideoView!)        }
        
        if !self.connected {
            self.connected = true
            self.setConnectionState(state: "connected")
        }
        
        let _msg: JSON = [
            "action": "consuming",
            "sessionId": self.sessionId!,
            "consumerId": consumeId,
            "peerId": self.peerId!
        ]
        
        self.socket.send(message: _msg)
        
        print("HandleNewConsumer() consuming \(kind) -> id =" + kindConsumer.getId())
        
    }
    
    func HandleNewDataConsumer() {
        
    }
    
    func HandleNewMessage() {
        
    }
    
    func SendNewMessage() {
        
    }
    
    func toggleCamera() {
        if self.videoEnabled {
            self.mediaCapturer.disableVideo()
            self.videoEnabled = false
        } else {
            self.mediaCapturer.enableVideo()
            self.videoEnabled = true
        }
    }
    
    func toggleCamerafacing() throws {
        if self.camera_facing == "front" {
            self.camera_facing = "back"
        } else if self.camera_facing == "back" {
            self.camera_facing = "front"
        }
        
        self.mediaCapturer.removeVideoTrack(view: self.localVideoView!)
        let videoTrack: RTCMediaStreamTrack = try self.mediaCapturer.createVideoTrack(videoView: self.localVideoView!, facing: self.camera_facing)
        
        for (_, producer) in self.producers {
            if producer.getKind() == "video" {
                //producer.replace(videoTrack)
                print(videoTrack.kind)
            }
        }
    }
    
    func setMicOpen() {
        self.mediaCapturer.enableAudio()
        self.audioEnabled = true
    }
    
    func setMicClosed() {
        self.mediaCapturer.disableAudio()
        self.audioEnabled = false
    }
    
    func toggleMicrophone() {
        if self.audioEnabled {
            setMicClosed()
        } else {
            setMicOpen()
        }
    }
    
    func DeclineCall(userId: String, sessionId: String, action: @escaping (()->())) {
        if self.socket.isConnected {
            let _msg: JSON = [
                "action": "decline-call",
                "sessionId": sessionId,
                "clientId": userId
            ]
            
            self.socket.send(message: _msg)
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.NETWORK_ATTEMPTS >= 10 {
                    action()
                }
                self.NETWORK_ATTEMPTS += 1
                self.DeclineCall(userId: userId, sessionId: sessionId, action: action)
            }
        }
        
    }
    
    func HandleCallEnded() {
        self.HandleCallSessionEnd()
        self.setConnectionState(state: "ended")
    }
    
    func HandleCallSessionEnd() {
        print("HandleCallSessionEnd()")
        self.mediaCapturer.stopTracks()
    }
    
    func EndCall(action: @escaping (() -> ())) {
        
        print("EndCall()")
        
        self.HandleCallSessionEnd()
        
        if self.connected || self.connection_state == "initializing" || self.connection_state == "ended" {
            let _msg: JSON = [
                "action" : "end-call",
                "sessionId" : self.sessionId!,
                "peerId": self.peerId!
            ]
            self.socket.send(message: _msg)
        }
        
        action()
        
    }
    
    func HandleDeclined() {
        self.setConnectionState(state: "declined")
    }
    
    func HandleSocketOpen() {
        print("HandleSocketOpen()")
    }
    
    func HandleSocketClose() {
        print("HandleSocketClose()")
    }
    
    func close() {
        self.socket.close()
    }
    
    private func handleLocalTransportConnectEvent(transport: Transport, dtlsParameters: String) {
        print("handleLocalTransportConnectEvent() id =" + transport.getId())
        //Request.shared.sendConnectWebRtcTransportRequest(socket: self.socket, roomId: self.roomId, transportId: transport.getId(), dtlsParameters: dtlsParameters)
        
        print("Connect Event")
        
        let _msg: JSON = [
            "action": "connect-transport",
            "peerId": self.peerId!,
            "sessionId": self.sessionId!,
            "transportId": transport.getId() as String,
            "dtlsParameters": JSON.init(parseJSON: dtlsParameters)
        ]
        
        self.socket.send(message: _msg)
    }
    
    private func HandleProduceRequest(message: JSON) {
        
        self.SocketQueue["produce"]?(message)
    }
    
    // Class to handle send transport listener events
    private class SendTransportHandler : NSObject, SendTransportListener {
        fileprivate weak var delegate: SendTransportListener?
        private var parent: CallSession
        
        init(parent: CallSession) {
            self.parent = parent
        }
        
        func onConnect(_ transport: Transport!, dtlsParameters: String!) {
            print("SendTransport::onConnect dtlsParameters = " + dtlsParameters)
            self.parent.handleLocalTransportConnectEvent(transport: transport, dtlsParameters: dtlsParameters)
        }
        
        func onConnectionStateChange(_ transport: Transport!, connectionState: String!) {
            print("SendTransport::onConnectionStateChange connectionState = " + connectionState)
            if connectionState == "diconnected" || connectionState == "failed" {
                transport.close()
                for (_, producer) in self.parent.producers {
                    producer.close()
                }
            }
        }
        
        func onProduce(_ transport: Transport!, kind: String!, rtpParameters: String!, appData: String!, callback: ((String?) -> Void)!) {
            //let producerId = self.parent.handleLocalTransportProduceEvent(transport: transport, kind: kind, rtpParameters: rtpParameters, appData: appData)
            
            print("onProduce Event")
            
            let _msg: JSON = [
                "action" : "produce",
                "peerId": self.parent.peerId!,
                "sessionId": self.parent.sessionId!,
                "transportId": transport.getId() as String,
                "kind": kind as String,
                "rtpParameters": JSON.init(parseJSON: rtpParameters)
            ]
            
            self.parent.socket.send(message: _msg)
            
            func action(message: JSON) {
                let producerId = message["id"].stringValue
                callback(producerId)
                print("--- producer callback ----")
                self.parent.SocketQueue.removeValue(forKey: "produce")
                
            }
            
            self.parent.SocketQueue["produce"] = action
        }
    }
    
    // Class to handle recv transport listener events
    private class RecvTransportHandler : NSObject, RecvTransportListener {
        fileprivate weak var delegate: RecvTransportListener?
        private var parent: CallSession
        
        init(parent: CallSession) {
            self.parent = parent
        }
        
        func onConnect(_ transport: Transport!, dtlsParameters: String!) {
            print("RecvTransport::onConnect")
            self.parent.handleLocalTransportConnectEvent(transport: transport, dtlsParameters: dtlsParameters)
        }
        
        func onConnectionStateChange(_ transport: Transport!, connectionState: String!) {
            print("RecvTransport::onConnectionStateChange newState = " + connectionState)
            if connectionState == "diconnected" || connectionState == "failed" {
                transport.close()
                for (_, consumer) in self.parent.consumers {
                    consumer.close()
                }
            }
        }
        
    }
    
    // Class to handle producer listener events
    private class ProducerHandler : NSObject, ProducerListener {
        fileprivate weak var delegate: ProducerListener?
        
        func onTransportClose(_ producer: Producer!) {
            print("Producer::onTransportClose")
        }
        
    }
    
    // Class to handle consumer listener events
    private class ConsumerHandler : NSObject, ConsumerListener {
        fileprivate weak var delegate: ConsumerListener?
        
        func onTransportClose(_ consumer: Consumer!) {
            print("Consumer::onTransportClose")
        }
    }
}
