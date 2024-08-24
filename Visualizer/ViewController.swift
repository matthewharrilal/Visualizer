import UIKit
import MetalKit

class MTViewController: UIViewController {
    var metalView: MetalView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()
        metalView = MetalView(frame: self.view.bounds, device: device)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(metalView)
        
        metalView.delegate = self
    }
}

extension MTViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes
    }

    func draw(in view: MTKView) {
        (view as? MetalView)?.render()
    }
}
