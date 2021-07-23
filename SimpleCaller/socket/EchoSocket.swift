//
//  EchoSocket.swift
//  SimeplCaller
//
//  Created by pzdev on 22/06/21.
//

import Foundation
import Starscream
import SwiftyJSON

class EchoSocket: WebSocketDelegate {
    
    private var wsURI: String;
    private var socket: WebSocket?
    public var isConnected: Bool = false
    
    let events = EventManager()
    
    init(wsURI: String) {
        self.wsURI = wsURI;
    }
    
    func connect() {
        var request = URLRequest(url: URL(string: self.wsURI)!)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        self.socket!.callbackQueue = DispatchQueue.global()
        self.socket?.delegate = self
        self.socket?.connect()
    }
    
    func close() {
        self.socket?.disconnect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            self.isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            self.isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            self.events.trigger(eventName: "message", information: string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            self.isConnected = false
        case .error(let error):
            self.isConnected = false
            self.events.trigger(eventName: "error", information: error)
        }
    }
    
    func send(message: JSON) {
        if let rawMessage = message.rawString() {
            self.socket?.write(string: rawMessage)
        } else {
            print("json.rawString is nil")
        }
    }
    
}
