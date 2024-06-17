import SwiftUI
import RealityKit

struct RealityKitView: UIViewRepresentable {
    
    @Binding var rotationAngle: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let anchor = AnchorEntity(world: .zero)
        
        let entity = try! Entity.load(named: "Floating_Lighthouse")
        
        let currentScale = entity.scale
        entity.scale = currentScale / 2
        
        let yRotation = simd_quatf(angle: Float.pi / 4, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 6, axis: [1, 0, 0])
        
        entity.transform.rotation = simd_mul(xRotation, yRotation)
        
        anchor.addChild(entity)
        
        arView.scene.addAnchor(anchor)
        
        context.coordinator.entity = entity
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
       
        guard let entity = context.coordinator.entity else { return }
        
        let yRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 6, axis: [1, 0, 0])
        let combinedRotation = simd_mul(xRotation, yRotation)
        
        entity.transform.rotation = combinedRotation
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(rotationAngle: $rotationAngle)
    }
    
    class Coordinator: NSObject {
        var entity: Entity?
        var rotationAngle: Binding<Float>
        var targetAngle: Float?
        var displayLink: CADisplayLink?
        
        init(rotationAngle: Binding<Float>) {
            self.rotationAngle = rotationAngle
        }
        
        func startRotationAnimation(to angle: Float) {
            targetAngle = angle
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
                //basicamente, o CADisplay funciona como um loop até chegar no ponto que a gente quer
                
                displayLink?.add(to: .main, forMode: .default)
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
    }
}


