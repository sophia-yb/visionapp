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
    private let visionProcessor = VisionProcessor()
    
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
    
    func updatePreviewLayerFrame() {
        DispatchQueue.main.async {
            guard let previewLayer = self.previewLayer else {return}
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                previewLayer.frame = window.bounds
                // print("Updated preview layer frame to: \(previewLayer.frame)")
            }
        }
    }
    
    
    //Sets up the capture session with the default camera.
    func setUpCaptureSession() async {
        guard await isAuthorized() else {
            print("Camera access not authorized")
            return
        }
        
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
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.addInput(videoDeviceInput)
        captureSession.commitConfiguration()
        
        // Set up the preview layer on the main thread
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.videoGravity = .resizeAspectFill
            self.updatePreviewLayerFrame()
        }
    }
    
    
    //Starts the camera session.
    func startSession() {
        DispatchQueue.global(qos: .background).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isCameraRunning = true
                    self.updatePreviewLayerFrame() // Ensure preview layer updates
                }
            } else {
                print("⚠️ Camera session was already running")
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
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        visionProcessor.processFrame(sampleBuffer) // Send frames to Vision
    }
}
