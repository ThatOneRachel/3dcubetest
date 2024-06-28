//
//  extensions.swift
//  3dcubetest
//
//  Created by Raquel Ramos on 28/06/24.
//

import Foundation
import RealityKit
import SwiftUI

extension RealityKitView {
    class Coordinator: NSObject {
        var entity: Entity?
        var cube: ModelEntity?
        var seed: Entity?
        var rotationAngle: Binding<Float>
        var cubePosition: Binding<SIMD3<Float>>
        var seedPosition: Binding<SIMD3<Float>>
        
        var targetAngle: Float?
        var displayLink: CADisplayLink?
        
        var targetPosition: SIMD3<Float>?
        var displayLinkForMovement: CADisplayLink?
        
        var lastPanLocation: CGPoint = .zero
        var isDraggingSeed = false
        
        init(rotationAngle: Binding<Float>, cubePosition: Binding<SIMD3<Float>>, seedPosition: Binding<SIMD3<Float>>) {
            self.rotationAngle = rotationAngle
            self.cubePosition = cubePosition
            self.seedPosition = seedPosition
        }
        
        func startRotationAnimation(to angle: Float) {
            targetAngle = angle
            
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
                displayLink?.add(to: .main, forMode: .default)
            }
        }
        
        func startMovimentationAnimation(to position: SIMD3<Float>) {
            targetPosition = position
            
            if displayLinkForMovement == nil {
                displayLinkForMovement = CADisplayLink(target: self, selector: #selector(updateMovement))
                displayLinkForMovement?.add(to: .main, forMode: .default)
            }
        }
        
        @objc func updateRotation() {
            guard let targetAngle = targetAngle else { return }
            let angleDifference = targetAngle - rotationAngle.wrappedValue
            let step: Float = 0.05
            
            if abs(angleDifference) < step {
                rotationAngle.wrappedValue = targetAngle
                displayLink?.invalidate()
                displayLink = nil
            } else {
                rotationAngle.wrappedValue += angleDifference > 0 ? step : -step
            }
        }
        
        @objc func updateMovement() {
            guard let targetPosition = targetPosition else { return }
            let positionDifference = targetPosition - cubePosition.wrappedValue
            let step: SIMD3<Float> = SIMD3<Float>(0.015, 0.015, 0.015)
            
            if length(positionDifference) < length(step) {
                cubePosition.wrappedValue = targetPosition
                displayLinkForMovement?.invalidate()
                displayLinkForMovement = nil
            } else {
                cubePosition.wrappedValue += normalize(positionDifference) * step
            }
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            guard let entity = entity else { return }
            guard let seed = seed else { return }
            
            let realSeed = seed.children.first!.children.first
            
            let location = sender.location(in: arView)
            let results = arView.hitTest(location, query: .nearest)
            
            if let firstResult = results.first {
                let touchedEntity = firstResult.entity
                
                if touchedEntity.name == entity.name {
                    let position = firstResult.position
                    let positionInScenery = entity.convert(position: position, from: nil)
                    startMovimentationAnimation(to: positionInScenery)
                    
                    print("DEBUG touched scenario entity", touchedEntity)
                } else if realSeed!.name == touchedEntity.parent!.name {
                    print("DEBUG touched seed")
                }
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            print(translation.x)
            if gesture.state == .ended {
                if translation.x > 0 {
                    startRotationAnimation(to: rotationAngle.wrappedValue + Float.pi / 2)
                } else {
                    startRotationAnimation(to: rotationAngle.wrappedValue - Float.pi / 2)
                }
            }
        }
    }
}
