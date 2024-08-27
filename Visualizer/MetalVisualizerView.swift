import MetalKit
import AVFoundation

let NUM_BALLS = 6 // Define NUM_BALLS globally so it can be accessed in the updateAudioData method

class MetaVisualizerView: MTKView {
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var time: Float = 0
    private var audioPlayer: AVAudioPlayer?
    private var audioData: [Float] = Array(repeating: 0.0, count: 6)

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
        
        setupAudio()
        createPipelineState()
    }

    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "your_audio_file", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.play()
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
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

    private func updateAudioData() {
        audioPlayer?.updateMeters()
        for i in 0..<NUM_BALLS {
            let averagePower = audioPlayer?.averagePower(forChannel: 0) ?? 0
            let normalizedPower = pow(10, averagePower / 20)
            audioData[i] = normalizedPower
        }
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let pipelineState = pipelineState,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }
        
        time += 1 / Float(preferredFramesPerSecond)
        updateAudioData()
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                              width: Double(drawableSize.width),
                                              height: Double(drawableSize.height),
                                              znear: 0, zfar: 1))
        
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        var resolution = simd_float2(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.size, index: 1)
        
        renderEncoder.setFragmentBytes(&audioData, length: MemoryLayout<Float>.size * NUM_BALLS, index: 2)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
