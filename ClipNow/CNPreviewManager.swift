//
//  CNPreviewManager.swift
//  ClipNow
//
//  Created by ruckef on 29.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

protocol CNPreviewManagerCaptureDelegate {
    func previewManagerDidStartCapturingPreviewVideo(successfull: Bool);
    func previewManagerDidFinishCapturingPreviewVideo(path: NSURL, error: NSError?);
}

class CNPreviewManager : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var previews = [GLKView]()
    let glContext: EAGLContext
    let ciContext: CIContext
    var scale = UIScreen.mainScreen().scale
    var settingUp = false
    
    // capturing video
    var captureDelegate: CNPreviewManagerCaptureDelegate?
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var framesWritten: Int64 = 0
    var capturing = false
    
    override init() {
        glContext = EAGLContext(API: .OpenGLES3)
        ciContext = CIContext(EAGLContext: glContext, options: [kCIContextWorkingColorSpace : NSNull()])
    }
    
    func fillBlack() {
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
    
    func clearPreviews() {
        if EAGLContext.currentContext() != glContext {
            EAGLContext.setCurrentContext(glContext)
        }
        for preview in previews  {
            preview.bindDrawable()
            fillBlack()
            preview.display()
            preview.deleteDrawable()
        }
    }
    
    func createPreview(frame: CGRect, isFront: Bool) -> UIView {
        let preview = GLKView(frame: frame, context: glContext)
        previews.append(preview)
        return preview
    }
    
    func startCapturingPreviewVideo(tempFilePathUrl: NSURL) {
        let outputSettings: [String:AnyObject] = [  AVVideoWidthKey     : 300,
                                                    AVVideoHeightKey    : 300,
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
            captureDelegate?.previewManagerDidStartCapturingPreviewVideo(success)
        }
    }
    
    func stopCapturingPreviewVideo() -> AVAssetWriter {
        capturing = false
        assetWriter?.finishWritingWithCompletionHandler({[unowned self] () -> Void in
            let url = (self.assetWriter?.outputURL)!
            self.captureDelegate?.previewManagerDidFinishCapturingPreviewVideo(url, error: self.assetWriter?.error)
        })
        return assetWriter!
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if settingUp {
            return
        }
        
        if EAGLContext.currentContext() != glContext {
            EAGLContext.setCurrentContext(glContext)
        }
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if let anImageBuffer = imageBuffer {
            if capturing {
                captureOutputImageBuffer(anImageBuffer)
            }
        }
        
        let image = CIImage(CVPixelBuffer: imageBuffer!, options: nil)
        
        for preview in previews  {
            var sourceRect = image.extent
            let sourceAspect = sourceRect.width / sourceRect.height
            var drawRect = preview.bounds
            drawRect.size.width *= scale
            drawRect.size.height *= scale
            let drawAspect = drawRect.width / drawRect.height
            if drawAspect < sourceAspect {
                sourceRect.origin.x += (sourceRect.width - sourceRect.height * drawAspect) / 2
                sourceRect.size.width = sourceRect.size.height * drawAspect
            } else {
                sourceRect.origin.y += (sourceRect.height - sourceRect.width / drawAspect) / 2
                sourceRect.size.height = sourceRect.width / drawAspect
            }
            
            preview.bindDrawable()
            fillBlack()
            glEnable(GLenum(GL_BLEND))
            glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
            
            ciContext.drawImage(image, inRect: drawRect, fromRect: sourceRect)
            preview.display()
            preview.deleteDrawable()
        }
    }
    
    func captureOutputImageBuffer(imageBuffer: CVImageBuffer) {
        if (assetWriterInput?.readyForMoreMediaData)! {
            pixelBufferAdaptor?.appendPixelBuffer(imageBuffer, withPresentationTime: CMTimeMake(framesWritten, 25))
            framesWritten++
        }
    }
}
