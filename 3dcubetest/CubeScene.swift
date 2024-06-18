import SwiftUI
import RealityKit

struct RealityKitView: UIViewRepresentable {
    
    @Binding var rotationAngle: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        
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
        
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
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
        
        var lastPanLocation: CGPoint = .zero
        var currentYRotation: Float = 0.0
        var currentXRotation: Float = 0.0
        
        init(rotationAngle: Binding<Float>) {
            self.rotationAngle = rotationAngle
        }
        

        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let entity = entity else { return }
            
            let translation = gesture.translation(in: gesture.view)
            let yRotationAngle = Float(translation.x) * (Float.pi / 180) // Convert to radians

            if gesture.state == .changed {
                currentYRotation += yRotationAngle / 10
                
                let yRotation = simd_quatf(angle: currentYRotation, axis: [0, 1, 0])
                let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
                
                let combinedRotation = simd_mul(xRotation, yRotation)
                entity.transform.rotation = combinedRotation
            }
            
            if gesture.state == .ended {
                lastPanLocation = .zero
            }
        }
        
    }
}


#Preview {
    ContentView()
}
