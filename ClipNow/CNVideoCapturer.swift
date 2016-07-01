//
//  CNVideoCapturer.swift
//  ClipNow
//
//  Created by ruckef on 01.07.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import AVFoundation

protocol CNVideoCapturerDelegate {
    func videoCapturerDidStartCapturingPreviewVideo(capturer:CNVideoCapturer, successfull: Bool)
    func videoCapturerDidFinishCapturingPreviewVideo(capturer:CNVideoCapturer, path: NSURL, error: NSError?)
}

class CNVideoCapturer {
    
    var delegate: CNVideoCapturerDelegate?
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var framesWritten: Int64 = 0
    var capturing = false
    
    func startCapturingPreviewVideo(tempFilePathUrl: NSURL, videoSize: CGSize) {
        let outputSettings: [String:AnyObject] = [  AVVideoWidthKey     : videoSize.width,
                                                    AVVideoHeightKey    : videoSize.height,
                                                    AVVideoCodecKey     : AVVideoCodecH264]
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        let pixelBufferAttributes : [String:AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput!, sourcePixelBufferAttributes: pixelBufferAttributes)
        do {
            assetWriter = try AVAssetWriter(URL: tempFilePathUrl, fileType: AVFileTypeMPEG4)
        } catch (let error as NSError) {
            print(error.localizedDescription)
        }
        if (assetWriter?.canAddInput(assetWriterInput!))! {
            assetWriter?.addInput(assetWriterInput!)
        }
        assetWriterInput?.expectsMediaDataInRealTime = true
        if (assetWriter?.startWriting())! {
            assetWriter?.startSessionAtSourceTime(kCMTimeZero)
            framesWritten = 0
            capturing = true
            
            var success = false
            switch (assetWriter?.status)! {
            case .Writing :
                success = true
            default: break
            }
            delegate?.videoCapturerDidStartCapturingPreviewVideo(self, successfull: success)
        }
    }
    
    func stopCapturingPreviewVideo() -> AVAssetWriter {
        capturing = false
        assetWriter?.finishWritingWithCompletionHandler({[unowned self] () -> Void in
            let url = (self.assetWriter?.outputURL)!
            self.delegate?.videoCapturerDidFinishCapturingPreviewVideo(self, path: url, error: self.assetWriter?.error)
            })
        return assetWriter!
    }
    
    func appendImageBuffer(imageBuffer: CVImageBuffer) {
        if (assetWriterInput?.readyForMoreMediaData)! {
            pixelBufferAdaptor?.appendPixelBuffer(imageBuffer, withPresentationTime: CMTimeMake(framesWritten, 25))
            framesWritten++
        }
    }
}
