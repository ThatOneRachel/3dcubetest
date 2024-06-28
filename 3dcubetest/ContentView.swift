//
//  ContentView.swift
//  3dcubetest
//
//  Created by Raquel Ramos on 17/06/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var rotationAngle: Float = 5 * Float.pi / 4
    
    var body: some View {
        VStack {
            RealityKitView(rotationAngle: $rotationAngle)
                .edgesIgnoringSafeArea(.all)
           
        }
    }
    
    func makeCoordinator() -> RealityKitView.Coordinator? {
        RealityKitView(rotationAngle: $rotationAngle).makeCoordinator()
    }
}

#Preview {
    ContentView()
}
