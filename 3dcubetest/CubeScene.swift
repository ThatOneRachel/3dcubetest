import SwiftUI
import RealityKit

struct RealityKitView: UIViewRepresentable {
    
    @Binding var rotationAngle: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.debugOptions.insert(.showStatistics)
        
        let anchor = AnchorEntity(world: .zero)
        
        //cenário
        let entity = try! Entity.load(named: "Floating_Lighthouse")
        
        let currentScale = entity.scale
        entity.scale = currentScale / 5
        
        let yRotation = simd_quatf(angle: Float.pi / 4, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        
        entity.transform.rotation = simd_mul(xRotation, yRotation)
        
        anchor.addChild(entity)
        
        //personagem
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let cube = ModelEntity(mesh: mesh, materials: [material])
        
        
        
        cube.transform.rotation = simd_mul(xRotation, yRotation)
        
        let bounds = entity.visualBounds(relativeTo: nil)
        let cornerPosition = SIMD3<Float>(bounds.max.x / 2, bounds.max.y / 2, bounds.max.z)
    
        cube.position = cornerPosition
        
        print("cenário", entity.visualBounds(relativeTo: nil))
        print("cubo", cube.position)
        
        anchor.addChild(cube)
        
        arView.scene.addAnchor(anchor)
        
        context.coordinator.entity = entity
        context.coordinator.cube = cube
        
       
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        guard let entity = context.coordinator.entity else { return }
        guard let cube  = context.coordinator.cube else { return }
        
        let yRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        let combinedRotation = simd_mul(xRotation, yRotation)
        
        entity.transform.rotation = combinedRotation
        cube.transform.rotation = combinedRotation
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(rotationAngle: $rotationAngle)
    }
    
    class Coordinator: NSObject {
        var entity: Entity?
        var cube: ModelEntity?
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


#Preview {
    ContentView()
}
