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
    
    
}

#Preview {
    ContentView()
}
