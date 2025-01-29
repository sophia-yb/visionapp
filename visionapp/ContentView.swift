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
    @StateObject private var visionProcessor = VisionProcessor()
    
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
            
            Rectangle()
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: 100, height: 100)
                .position(x: 200, y: 400)
            
            let screenSize = UIScreen.main.bounds.size
            ForEach(visionProcessor.detectedObjects, id: \.id) { object in
                //print("📦 SwiftUI detected object for BoundingBoxView: \(object.label) at \(object.boundingBox)")
                BoundingBoxView(object: object, screenSize: screenSize)
            }

            // Overlay: Show camera state
            VStack {
                // Velocity graph
//                MotionGraphView(motionData: visionProcessor.velocityData, title: "Velocity (px/s)")
//                // Acceleration graph
//                MotionGraphView(motionData: visionProcessor.accelerationData, title: "Acceleration (px/s^2)")
                Spacer()
                .padding()
            }
        }
        .onAppear {
            Task {
                await cameraManager.setUpCaptureSession()
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}
