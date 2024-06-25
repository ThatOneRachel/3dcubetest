import SwiftUI
import RealityKit

struct RealityKitView: UIViewRepresentable {
    
    @Binding var rotationAngle: Float
    
    @State var cubePosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0.5)
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.debugOptions.insert(.showPhysics)
        
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
        
        //cenário
        //let entity = try! ModelEntity.load(named: "isometrico")
        let mesh1 = MeshResource.generateBox(width: 0.7, height: 0.2, depth: 0.7)
        let material1 = SimpleMaterial(color: .red, isMetallic: false)
        let entity = ModelEntity(mesh: mesh1, materials: [material1])
        
        let currentScale = entity.scale
        entity.scale = currentScale
        
        let yRotation = simd_quatf(angle: Float.pi / 4, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        
        entity.transform.rotation = simd_mul(xRotation, yRotation)
        
        //        let components = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.1, 0.1, 0.1))])
        //        entity.components.set(components)
        entity.generateCollisionShapes(recursive: true)
        
        
        anchor.addChild(entity)
        
        //personagem
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let cube = ModelEntity(mesh: mesh, materials: [material])
        
        
        cube.position = cubePosition
        
        cube.generateCollisionShapes(recursive: true)
        
        print("cenário", entity.visualBounds(relativeTo: nil))
        print("cubo", cube.position)
        
        entity.addChild(cube)
        
        arView.scene.addAnchor(anchor)
        
        
        //passa pro coordinator
        context.coordinator.entity = entity
        context.coordinator.cube = cube
        
        
        //MARK: TAP GESTURES
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        guard let entity = context.coordinator.entity else { return }
        guard let cube  = context.coordinator.cube else { return }
        
        let yRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        let combinedRotation = simd_mul(xRotation, yRotation)
        
        entity.transform.rotation = combinedRotation
        cube.setPosition(cubePosition, relativeTo: entity)
        print("posição do cube em relação a entidade", cube.position)
        print("posição do cube em relação a nil", cube.position(relativeTo: nil))
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(rotationAngle: $rotationAngle, cubePosition: $cubePosition)
    }
    
    class Coordinator: NSObject {
        var entity: Entity?
        var cube: ModelEntity?
        var rotationAngle: Binding<Float>
        var cubePosition: Binding<SIMD3<Float>>
        var targetAngle: Float?
        var displayLink: CADisplayLink?
        
        
        var lastPanLocation: CGPoint = .zero
        var currentYRotation: Float = 0.0
        var currentXRotation: Float = 0.0
        
        
        init(rotationAngle: Binding<Float>, cubePosition: Binding<SIMD3<Float>>) {
            self.rotationAngle = rotationAngle
            self.cubePosition = cubePosition
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
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            let location = sender.location(in: arView)
            
            let results = arView.hitTest(location, query: .nearest)
            if let firstResult = results.first {
                let hitEntity = firstResult.entity
                let touchPositionInWorld = firstResult.position
                if let largerCube = entity {
                    let touchPositionInLargerCube = largerCube.convert(position: touchPositionInWorld, from: nil)
                    cubePosition.wrappedValue = touchPositionInLargerCube
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


#Preview {
    ContentView()
}
