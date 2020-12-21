//
//  AudioDataFromFile.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//

import AVFoundation

// A big hammer: return ALL audio data from a file. Probably best only for testing/demo.
func AudioDataFromFile(url: URL, sampleRate: Float = 44100) -> [Float]? {
    let avAsset: AVURLAsset = AVURLAsset(url: url)
        
    let assetReader: AVAssetReader
    do {
        assetReader = try AVAssetReader(asset: avAsset)
    } catch let e as NSError {
        Logger.log("*** AVAssetReader failed with \(e)")
        return nil
    }
    
    let settings: [String : AnyObject] = [ AVFormatIDKey : Int(kAudioFormatLinearPCM) as AnyObject,
                                           AVSampleRateKey : sampleRate as AnyObject,
                                           AVLinearPCMBitDepthKey : 32 as AnyObject,
                                           AVLinearPCMIsFloatKey : true as AnyObject,
                                           AVNumberOfChannelsKey : 1 as AnyObject ]
    
    let output: AVAssetReaderAudioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: avAsset.tracks, audioSettings: settings)
    
    assetReader.add(output)
    
    if !assetReader.startReading() {
        Logger.log("assetReader.startReading() failed")
        return nil
    }
        
    var fileSamples: [Float] = [Float]()
    
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
        
        status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(nextBuffer,
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
                fileSamples.append(sample)
            }
        }
    } while true
    
    return fileSamples
}
