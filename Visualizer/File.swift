//
//  File.swift
//  Visualizer
//
//  Created by Space Wizard on 8/24/24.
//

import Foundation
import AVFoundation

class AudioVisualizer {
    private var audioEngine = AVAudioEngine()
    private var audioPlayerNode = AVAudioPlayerNode()
    private var mixerNode: AVAudioMixerNode {
        return audioEngine.mainMixerNode
    }
    
    func start() {
        audioEngine.attach(audioPlayerNode)
        let format = mixerNode.outputFormat(forBus: 0)
        audioEngine.connect(audioPlayerNode, to: mixerNode, format: format)
        
        audioPlayerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            // Process audio buffer here
            self.processAudio(buffer: buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    private func processAudio(buffer: AVAudioPCMBuffer) {
        // Implement your audio processing and visualization logic here
    }
}
