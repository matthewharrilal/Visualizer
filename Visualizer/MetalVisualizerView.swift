import UIKit
import Metal
import MetalKit

class MetalView: MTKView {
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var timer: Timer?
    private var time: Float = 0.0

    private var vertices: [float4] = []
    private let numVertices = 300 // Increased for a more complex ribbon effect

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        guard let device = self.device else {
            fatalError("Metal device is not initialized")
        }

        commandQueue = device.makeCommandQueue()

        // Load and compile shaders
        let library = try! device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")!
        let fragmentFunction = library?.makeFunction(name: "fragment_main")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<float4>.size
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // Setup vertex data
        setupVertices()

        // Start a timer to update the visualizer
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateVertices()
            self.render()
        }
    }

    private func setupVertices() {
        // Initialize vertices in a circular pattern for a ribbon-like effect
        let radius: Float = 0.8
        vertices.removeAll()

        for i in 0..<numVertices {
            let angle = Float(i) / Float(numVertices) * 2.0 * Float.pi
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            vertices.append(float4(x, y, 0.0, 1.0))
        }

        let dataSize = vertices.count * MemoryLayout<float4>.size
        vertexBuffer = device?.makeBuffer(bytes: vertices, length: dataSize, options: .storageModeShared)
    }

    private func updateVertices() {
        // No need to update vertices, swirl pattern is handled by vertex shader via time
        time += 0.05
    }

    func render() {
        guard let drawable = currentDrawable else { return }
        let renderPassDescriptor = self.currentRenderPassDescriptor!

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Set the time buffer
        var timeCopy = time // Metal expects a pointer, so we use var here
        renderCommandEncoder.setVertexBytes(&timeCopy, length: MemoryLayout<Float>.size, index: 1)

        renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: numVertices)
        renderCommandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
