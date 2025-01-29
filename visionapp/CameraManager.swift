//
//  CameraManager.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import Foundation
import AVFoundation
import SwiftUI


class CameraManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    
    
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isCameraRunning = false
    
    
    //Checks if the app has camera authorization and requests permission if not determined.
    func isAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        
        if status == .authorized {
            print("Camera access authorized")
            return true
        } else if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("Camera access \(granted ? "granted" : "denied")")
            return granted
        } else {
            print("Camera access denied")
            return false
        }
    }
    
    
    //Sets up the capture session with the default camera.
    func setUpCaptureSession() async {
        guard await isAuthorized() else {
            print("Camera access not authorized")
            return
        }
        
        print("Starting camera session configuration")
        // Start configuring the session
        captureSession.beginConfiguration()
        
        
        // Add the default video device as input
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else {
            print("Failed to configure capture session")
            captureSession.commitConfiguration()
            return
        }
        
        
        captureSession.addInput(videoDeviceInput)
        captureSession.commitConfiguration()
        
        print("Capture session configured successfully")
        
        // Set up the preview layer on the main thread
        DispatchQueue.main.async {
            let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            layer.videoGravity = .resizeAspectFill
            self.previewLayer = layer
            print("Preview Layer assigned: \(self.previewLayer != nil ? "Yes" : "No")")
        }
    }
    
    
    //Starts the camera session.
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { // Run on a background thread
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isCameraRunning = true
                    print("Camera session started")
                }
            } else {
                print("Camera session is already running")
            }
        }
    }

    
    
    //Stops the camera session.
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { // Run on a background thread
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isCameraRunning = false
                    print("Camera session stopped")
                }
            } else {
                print("Camera session was not running")
            }
        }
    }
}
