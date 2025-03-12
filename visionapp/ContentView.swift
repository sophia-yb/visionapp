//
//  ContentView.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import SwiftUI
import AVFoundation


struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject var visionProcessor = VisionProcessor()
    
    // Motion Data
    @State private var velocityData: [(time: Double, value: Double)] = []
    @State private var accelerationData: [(time: Double, value: Double)] = []
    @State private var startTime = Date()
    

    var body: some View {
        ZStack {
            // Camera feed
            if let previewLayer = cameraManager.previewLayer {
                CameraPreview(previewLayer: previewLayer)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .edgesIgnoringSafeArea(.all) // Ensure full-screen display
            } else {
                Text("Camera not available")
            }
            
            let screenSize = UIScreen.main.bounds.size
            
            VStack {
                Text("Detected Objects: \(visionProcessor.detectedObjects.count)")
                    .foregroundColor(.white)
                    .padding()
                
                if visionProcessor.detectedObjects.isEmpty {
                    Text("❌ No objects detected").foregroundColor(.red)
                } else {
                    ForEach(Array(visionProcessor.detectedObjects), id: \.id) { object in
                        Text("📦 Detected object: \(object.label)")
                    }
                }
            }
        }
        .onAppear {
            Task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("🟢 UI Checking Detected Objects (Inside ContentView): \(visionProcessor.detectedObjects)")
                }
                await cameraManager.setUpCaptureSession()
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}
