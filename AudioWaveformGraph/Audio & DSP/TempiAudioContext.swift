//
//  TempiAudioContext.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//

import AVFoundation

class TempiAudioContext {
    
    let sampleCnt: Int // Total number of samples in loaded asset
    var sampleRate: Double = 0
    var sampleMax: Float = -Float.greatestFiniteMagnitude
    var sampleMin: Float = Float.greatestFiniteMagnitude
    private let audioURL: URL
    let asset: AVAsset
    let assetTrack: AVAssetTrack
    
    private init(audioURL: URL, totalSamples: Int, asset: AVAsset, assetTrack: AVAssetTrack) {
        self.audioURL = audioURL
        self.sampleCnt = totalSamples
        self.asset = asset
        self.assetTrack = assetTrack
    }
    
    class func load(
        fromAudioURL audioURL: URL,
        completionHandler: @escaping (_ audioContext: TempiAudioContext?) -> ()) {
        
        let asset = AVURLAsset(
            url: audioURL,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])
        
        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
            NSLog("TempiAudioContext failed to load AVAssetTrack")
            completionHandler(nil)
            return
        }
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
                case .loaded:
                    guard
                        let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
                        let audioFormatDesc = formatDescriptions.first,
                        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                    else { break }
                    
                    let sampleRate = asbd.pointee.mSampleRate
                    let totalSamples = Int(sampleRate * Float64(asset.duration.value) / Float64(asset.duration.timescale))
                    
                    let audioContext = TempiAudioContext(
                        audioURL: audioURL,
                        totalSamples: totalSamples,
                        asset: asset,
                        assetTrack: assetTrack)
                    
                    audioContext.sampleRate = sampleRate
                    DispatchQueue.main.async {
                        completionHandler(audioContext)
                    }
                    return
                case .failed, .cancelled, .loading, .unknown:
                    Logger.log("*** TempiAudioContext could not load asset: \(error?.localizedDescription ?? "Unknown error")")
                @unknown default:
                    assertionFailure()
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func readSamples(completion: @escaping (_ samples: [Float]?) -> ()) {
        DispatchQueue.global().async {
            let samples = self.readSamplesSync()
            DispatchQueue.main.async {
                completion(samples)
            }
        }
    }
    
    private func readSamplesSync() -> [Float]? {
        let assetReader: AVAssetReader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch let e as NSError {
            NSLog("*** AVAssetReader failed with \(e)")
            return nil
        }

        let settings: [String : Any] = [ AVFormatIDKey : Int(kAudioFormatLinearPCM),
                                         AVSampleRateKey : sampleRate,
                                         AVLinearPCMBitDepthKey : 32,
                                         AVLinearPCMIsFloatKey : true,
                                         AVNumberOfChannelsKey : 1 ]
        
        let output: AVAssetReaderAudioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: asset.tracks, audioSettings: settings)
        
        assetReader.add(output)
        
        if !assetReader.startReading() {
            Logger.log("*** assetReader.startReading() failed")
            return nil
        }
        
        var samples: [Float] = [Float]()
        
        repeat {
            var status: OSStatus = 0
            guard let nextBuffer = output.copyNextSampleBuffer() else {
                break
            }
            
            let bufferSampleCnt = CMSampleBufferGetNumSamples(nextBuffer)
            
            var bufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 1,
                    mDataByteSize: 4,
                    mData: nil))
            
            var blockBuffer: CMBlockBuffer?
            
            status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                nextBuffer,
                bufferListSizeNeededOut: nil,
                bufferListOut: &bufferList,
                bufferListSize: MemoryLayout<AudioBufferList>.size,
                blockBufferAllocator: nil,
                blockBufferMemoryAllocator: nil,
                flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                blockBufferOut: &blockBuffer)
            
            if status != 0 {
                Logger.log("*** CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed with error \(status)")
                break
            }
            
            // Move samples from mData into our native [Float] format.
            let audioBuffer = AudioBuffer(mNumberChannels: bufferList.mBuffers.mNumberChannels,
                                          mDataByteSize: bufferList.mBuffers.mDataByteSize,
                                          mData: bufferList.mBuffers.mData)
            let data = UnsafeRawPointer(audioBuffer.mData)
            for i in 0..<bufferSampleCnt {
                if let sample = data?.load(fromByteOffset: i*4, as: Float.self) {
                    samples.append(sample)
                    if sample > sampleMax {
                        sampleMax = sample
                    }
                    if sample < sampleMin {
                        sampleMin = sample
                    }
                }
            }
        } while true
        
        return samples
    }
}
