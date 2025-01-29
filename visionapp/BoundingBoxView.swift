//
//  BoundingBoxView.swift
//  visionapp
//
//  Created by Sophia Buda on 2/5/25.
//

import SwiftUI
import Vision


struct BoundingBoxView: View {
    var object: DetectedObject
    var screenSize: CGSize

    var body: some View {
        let box = object.boundingBox
        let x = max(0, min(box.minX * screenSize.width, screenSize.width))
        let y = max(0, min((1 - box.maxY) * screenSize.height, screenSize.height))
        let width = max(2, min(box.width * screenSize.width, screenSize.width - x))
        let height = max(2, min(box.height * screenSize.height, screenSize.height - y))

        print("Drawing BoundingBoxView: \(object.label), x=\(x), y=\(y), width=\(width), height=\(height)")
        
        return ZStack {
            Rectangle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: width, height: height)
                .position(x: x + width / 2, y: y + height / 2)
        }
    }
}


