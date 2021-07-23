//
//  MediaCapturer.swift
//  SimeplCaller
//
//  Created by pzdev on 26/05/21.
//

import Foundation
import WebRTC

public enum MediaError : Error {
    case CAMERA_DEVICE_NOT_FOUND
    case CAMERA_FACING_NOT_FOUND
}

final internal class MediaCapturer : NSObject, RTCAudioSessionDelegate {
    private static let MEDIA_STREAM_ID: String = "ARDAMS"
    private static let VIDEO_TRACK_ID: String = "ARDAMSv0"
    private static let AUDIO_TRACK_ID: String = "ARDAMSa0"
    
    private let peerConnectionFactory: RTCPeerConnectionFactory
    internal let mediaStream: RTCMediaStream
    
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?
    internal var videoTrack: RTCVideoTrack?
    internal var audioTrack: RTCAudioTrack?
    
    internal static let shared = MediaCapturer.init();
    
    private override init() {
        self.peerConnectionFactory = RTCPeerConnectionFactory.init();
        self.mediaStream = self.peerConnectionFactory.mediaStream(withStreamId: MediaCapturer.MEDIA_STREAM_ID)
    }
    
    internal func createVideoTrack(videoView: RTCMTLVideoView, facing: String) throws -> RTCVideoTrack {
        // Get the front camera for now
        var devices: [AVCaptureDevice]

        if facing == "front" {
            // If using iOS 10.2 or above use the new API
            if #available(iOS 10.2, *) {
                devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices;
            
            } else {
                // Older than iOS 10.1
                devices = AVCaptureDevice.devices().filter({ $0.position == .front });
            }
        } else if facing == "back" {
            // If using iOS 10.2 or above use the new API
            if #available(iOS 10.2, *) {
                devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices;
            } else {
                // Older than iOS 10.1
                devices = AVCaptureDevice.devices().filter({ $0.position == .back });
            }
        } else {
            throw MediaError.CAMERA_FACING_NOT_FOUND
        }
        
        print("createVideoTrack() got device count = " + devices.count.description)
        
        // throw an error if there are no devices
        if (devices.count == 0) {
            throw MediaError.CAMERA_DEVICE_NOT_FOUND;
        }
        print("createVideoTrack() use device " + devices[0].description)
        
        // if there is a device start capturing it
        
        self.videoCapturer = RTCCameraVideoCapturer.init();
        self.videoCapturer!.delegate = self
        self.videoCapturer!.startCapture(with: devices[0], format: devices[0].activeFormat, fps: 30);
        self.videoSource = self.peerConnectionFactory.videoSource();
        
        self.videoSource!.adaptOutputFormat(toWidth: 640, height: 480, fps: 30);
        
        let videoTrack: RTCVideoTrack = self.peerConnectionFactory.videoTrack(with: self.videoSource!, trackId: NSUUID().uuidString)
        self.mediaStream.addVideoTrack(videoTrack)
        
        videoTrack.isEnabled = true
        
        videoTrack.add(videoView)
        
        self.videoTrack = videoTrack
        
        return videoTrack
    }
    
    internal func getBackCameraTrack() {
    }
    
    internal func createAudioTrack() -> RTCAudioTrack {
        let audioTrack: RTCAudioTrack = self.peerConnectionFactory.audioTrack(withTrackId: NSUUID().uuidString)
        audioTrack.isEnabled = true
        self.mediaStream.addAudioTrack(audioTrack)
        
        self.audioTrack = audioTrack
        return audioTrack
    }

    
    internal func stopTracks() {

        self.videoCapturer?.captureSession.stopRunning()
        self.videoCapturer = nil
       
        if self.audioTrack != nil {
            self.mediaStream.removeAudioTrack(self.audioTrack!)
            self.audioTrack = nil
        }
        
        if self.videoTrack != nil {
            self.mediaStream.removeVideoTrack(self.videoTrack!)
            self.videoTrack = nil
        }
        
    }
    
    internal func removeVideoTrack(view: RTCMTLVideoView) {
        self.videoCapturer?.stopCapture()
        self.videoTrack?.remove(view)
        self.mediaStream.removeVideoTrack(self.videoTrack!)
    }
    
    internal func disableAudio() {
        self.audioTrack?.isEnabled = false
    }
    
    internal func enableAudio() {
        self.audioTrack?.isEnabled = true
    }
    
    internal func disableVideo() {
        self.videoTrack?.isEnabled = false
    }
    
    internal func enableVideo() {
        self.videoTrack?.isEnabled = true
    }
}

extension MediaCapturer : RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.videoSource?.capturer(capturer, didCapture: frame)
    }
}
