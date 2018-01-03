//
//  CNVideoCapturer.swift
//  ClipNow
//
//  Created by ruckef on 01.07.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import AVFoundation
import CoreAudio

protocol CNVideoCapturerDelegate {
    func videoCapturerDidStartCapturingPreviewVideo(_ capturer:CNVideoCapturer, successfull: Bool)
    func videoCapturerDidFinishCapturingPreviewVideo(_ capturer:CNVideoCapturer, path: URL, error: NSError?)
}

class CNVideoCapturer {
    
    var delegate: CNVideoCapturerDelegate?
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var audioWriterInput: AVAssetWriterInput?
    var framesWritten: Int64 = 0
    var capturing = false
    
    func startCapturingPreviewVideo(_ tempFilePathUrl: URL, videoSize: CGSize, audioSettings: [String:AnyObject]?, fileType: String) {
        let outputSettings: [String:AnyObject] = [  AVVideoWidthKey     : videoSize.width as AnyObject,
                                                    AVVideoHeightKey    : videoSize.height as AnyObject,
                                                    AVVideoCodecKey     : AVVideoCodecH264 as AnyObject]
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let pixelBufferAttributes : [String:AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput!, sourcePixelBufferAttributes: pixelBufferAttributes)
        assetWriterInput?.expectsMediaDataInRealTime = true
        
//        audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
//        audioWriterInput?.expectsMediaDataInRealTime = true
        
        assetWriter = try? AVAssetWriter(outputURL: tempFilePathUrl, fileType: AVFileType(rawValue: fileType))
        if assetWriter!.canAdd(assetWriterInput!) {
            assetWriter?.add(assetWriterInput!)
        }
//        if assetWriter!.canAdd(audioWriterInput!) {
//            assetWriter?.add(audioWriterInput!)
//        }
        assetWriter?.canApply(outputSettings: audioSettings, forMediaType: AVMediaType.audio)
        
        if (assetWriter?.startWriting())! {
            assetWriter?.startSession(atSourceTime: kCMTimeZero)
            framesWritten = 0
            capturing = true
            
            var success = false
            switch (assetWriter?.status)! {
            case .writing :
                success = true
            default: break
            }
            delegate?.videoCapturerDidStartCapturingPreviewVideo(self, successfull: success)
        }
    }
    
    func stopCapturingPreviewVideo() -> AVAssetWriter {
        capturing = false
        assetWriterInput?.markAsFinished()
//        audioWriterInput?.markAsFinished()
        assetWriter?.finishWriting(completionHandler: {[unowned self] () -> Void in
            let url = (self.assetWriter?.outputURL)!
            self.delegate?.videoCapturerDidFinishCapturingPreviewVideo(self, path: url, error: self.assetWriter?.error as NSError?)
            })
        return assetWriter!
    }
    
    func appendImageBuffer(_ imageBuffer: CVImageBuffer) {
        guard capturing else {
            return
        }
        if assetWriterInput!.isReadyForMoreMediaData {
            pixelBufferAdaptor?.append(imageBuffer, withPresentationTime: CMTimeMake(framesWritten, 25))
            framesWritten += 1
        }
    }
    
    func appendAudioBuffer(_ audioDataBuffer: CMSampleBuffer) {
        guard capturing else {
            return
        }
        if audioWriterInput!.isReadyForMoreMediaData {
            var audioBufferList = AudioBufferList()
            var blockBuffer: CMBlockBuffer? = nil
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                audioDataBuffer,
                nil,
                &audioBufferList,
                Int(MemoryLayout<AudioBufferList>.size),
                nil,
                nil,
                UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
                &blockBuffer)
            assetWriterInput?.append(audioDataBuffer)
        }
    }
}
