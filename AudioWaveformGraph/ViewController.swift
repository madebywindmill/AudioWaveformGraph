//
//  ViewController.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var audioGraphView: AudioGraphView!
    
    private var audioContext: TempiAudioContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") else {
            fatalError()
        }
        
        TempiAudioContext.load(fromAudioURL: url) { (finishedContext) in
            guard let finishedContext = finishedContext else { return }
            self.audioContext = finishedContext
                        
            finishedContext.readSamples() { [weak self] (samples) in
                guard let self = self else { return }
                guard let samples = samples else { return }

                self.audioGraphView.setSamples(samples, sampleRate: finishedContext.sampleRate)
                self.audioGraphView.waveformColor = #colorLiteral(red: 0, green: 0.8695636392, blue: 0.5598542094, alpha: 1)
                self.audioGraphView.setNeedsLayout()
            }
            
        }
    }
}

