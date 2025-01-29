//
//  MotionGraphView.swift
//  visionapp
//
//  Created by Sophia Buda on 2/5/25.
//

import SwiftUI
import Charts


struct MotionGraphView: View {
    var motionData: [(time: Double, value: Double)] // Time vs. Motion Value
    var title: String // Graph title
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            
            Chart {
                ForEach(motionData, id: \.time) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.time),
                        y: .value("Value", dataPoint.value)
                    )
                    .interpolationMethod(.catmullRom) // Smooth curve
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 200)
            .padding()
        }
    }
}
