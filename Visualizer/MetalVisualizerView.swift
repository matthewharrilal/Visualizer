import MetalKit

class MetalView: MTKView {
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var time: Float = 0
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    private func commonInit() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        isPaused = false
        enableSetNeedsDisplay = false
        preferredFramesPerSecond = 60  // Target 60 FPS
        
        createPipelineState()
    }
    
    private func createPipelineState() {
        guard let device = device else { return }
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let pipelineState = pipelineState,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }
        
        time += 1 / Float(preferredFramesPerSecond)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                              width: Double(drawableSize.width),
                                              height: Double(drawableSize.height),
                                              znear: 0, zfar: 1))
        
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        var resolution = simd_float2(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.size, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
