//
//  ContentView.swift
//  3dcubetest
//
//  Created by Raquel Ramos on 17/06/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var rotationAngle: Float = Float.pi / 4
    
    var body: some View {
        VStack {
            RealityKitView(rotationAngle: $rotationAngle)
                .edgesIgnoringSafeArea(.all)
            //drag gesture vai por cima dessa camada do reality, então vou precisar fazer tudo pela realityView kkrying
//                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
//                    .onEnded({ value in
//                        
//                        if (abs(value.translation.height) < 100) {
//                            
//                            if value.translation.width > 2 {
//                                if let coordinator = self.makeCoordinator() {
//                                    coordinator.startRotationAnimation(to: rotationAngle + Float.pi / 2)
//                                }
//                            } else if value.translation.width < -2 {
//                                if let coordinator = self.makeCoordinator() {
//                                    coordinator.startRotationAnimation(to: rotationAngle - Float.pi / 2)
//                                }
//                            }
//                        }
//                        
//
//                    })
//                )
        }
    }
    
    func makeCoordinator() -> RealityKitView.Coordinator? {
        RealityKitView(rotationAngle: $rotationAngle).makeCoordinator()
    }
}

#Preview {
    ContentView()
}
