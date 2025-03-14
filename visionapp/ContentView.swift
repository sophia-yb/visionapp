//
//  ContentView.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import SwiftUI
import AVFoundation
import Combine


struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @EnvironmentObject var visionProcessor: VisionProcessor
    @State private var forceRefresh = false
    
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
            
            //let screenSize = UIScreen.main.bounds.size
            
            VStack {
                //Displays detected object count in UI
                Text("Detected Objects: \(visionProcessor.detectedObjectsList.objects.count)")
                    .foregroundColor(.white)
                    .padding()
                
                //These statements are mainly for debugging - testing if objects from VisionProcessor transfer to the UI
                .onAppear {
                    print("🟢 UI Appeared - detectedObjects count: \(visionProcessor.detectedObjectsList.objects.count)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        print("🟢 UI Checking detectedObjects after 2s: \(visionProcessor.detectedObjectsList.objects)")
                        }
                }
                .onChange(of: visionProcessor.detectedObjectsList.objects) { newObjects in
                    DispatchQueue.main.async {
                        print("🟢 UI Detected Change - detectedObjects count: \(newObjects.count)")
                        forceRefresh.toggle()
                    }
                }
                .onReceive(visionProcessor.objectWillChange) { _ in
                    print("🔄 SwiftUI received objectWillChange signal!")
                }
                .onReceive(Just(visionProcessor.detectedObjectsList.objects).removeDuplicates()) { objects in
                    print("📢 Just() triggered detectedObjects update: \(objects.count) objects")
                }


                //Prints detected objects by UI
                if visionProcessor.detectedObjectsList.objects.isEmpty {
                    Text("❌ No objects detected").foregroundColor(.red)
                } else {
                    ForEach(Array(visionProcessor.detectedObjectsList.objects), id: \.id) { object in
                        Text("📦 Detected object: \(object.label)")
                    }
                }
            }
        }
        //Stops and starts the camera session
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
