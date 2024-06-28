import SwiftUI
import RealityKit

struct RealityKitView: UIViewRepresentable {
    
    @Binding var rotationAngle: Float
    @State var cubePosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0.5)
    @State var seedPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.cameraMode = .nonAR
        arView.debugOptions.insert(.showPhysics)
        
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
        
        // Scenario
        let entity = try! ModelEntity.load(named: "cenaTeste2")
        entity.name = "cenario"
        
        let yRotation = simd_quatf(angle: Float.pi / 4, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        entity.transform.rotation = simd_mul(xRotation, yRotation)
        
        let components = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.55, 0.03, 0.55))])
        entity.components.set(components)
        
        anchor.addChild(entity)
        
        // Cube (personagem)
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let cube = ModelEntity(mesh: mesh, materials: [material])
        cube.name = "personagem"
        cube.position = cubePosition
        cube.generateCollisionShapes(recursive: true)
        entity.addChild(cube)
        
        // Seed (semente)
        let seed = try! ModelEntity.load(named: "cenaSemente")
        seed.generateCollisionShapes(recursive: true)
        seed.name = "semente"
        entity.addChild(seed)
        
        arView.scene.addAnchor(anchor)
        
        // Pass entities to coordinator
        context.coordinator.entity = entity
        context.coordinator.cube = cube
        context.coordinator.seed = seed
        
        // Add gesture recognizers
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
    
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        guard let entity = context.coordinator.entity else { return }
        guard let cube = context.coordinator.cube else { return }
        guard let seed = context.coordinator.seed else { return }
        
        let yRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        let xRotation = simd_quatf(angle: Float.pi / 4, axis: [1, 0, 0])
        let combinedRotation = simd_mul(xRotation, yRotation)
        
        entity.transform.rotation = combinedRotation
        cube.setPosition(cubePosition, relativeTo: entity)
        seed.setPosition(seedPosition, relativeTo: entity)
        
        print("Position of cube relative to entity:", cube.position)
        print("Position of cube relative to nil:", cube.position(relativeTo: nil))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(rotationAngle: $rotationAngle, cubePosition: $cubePosition, seedPosition: $seedPosition)
    }
    
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

#Preview {
    ContentView()
}
