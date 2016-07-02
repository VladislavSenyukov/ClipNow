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

protocol CNPreviewManagerDelegate {
    func previewManagerDidOutputImageBuffer(manager: CNPreviewManager, imageBuffer: CVImageBuffer)
}

class CNGLPreview: GLKView {
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }
}

class CNPreviewManager : NSObject {
    
    var delegate: CNPreviewManagerDelegate?
    var previews = [CNGLPreview]()
    let glContext: EAGLContext
    let ciContext: CIContext
    var cameraSourceResolution: CGSize = CGSizeZero
    var scale = UIScreen.mainScreen().scale
    var settingUp = false
    
    override init() {
        glContext = EAGLContext(API: .OpenGLES3)
        ciContext = CIContext(EAGLContext: glContext, options: [kCIContextWorkingColorSpace : NSNull()])
    }
    
    func stopRunning() {
        settingUp = true
        // for some reason this will crash occasionally if we want to have a fill color instead of a frozen image when switching cameras
//        clearPreviews()
    }
    
    func startRunning() {
        settingUp = false
    }
    
    func fillWithDefaultColor () {
        glClearColor(0.3, 0.3, 0.3, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }
    
    func clearPreviews() {
        if EAGLContext.currentContext() != glContext {
            EAGLContext.setCurrentContext(glContext)
        }
        for preview in previews  {
            preview.bindDrawable()
            fillWithDefaultColor()
            preview.display()
            preview.deleteDrawable()
        }
    }
    
    func createPreview(frame: CGRect, isFront: Bool) -> UIView {
        let preview = CNGLPreview(frame: frame, context: glContext)
        previews.append(preview)
        return preview
    }
}

extension CNPreviewManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if settingUp {
            return
        }
        
        if EAGLContext.currentContext() != glContext {
            EAGLContext.setCurrentContext(glContext)
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly)
        let image = CIImage(CVPixelBuffer: imageBuffer, options: nil)
        var sourceRect = image.extent
        let sourceAspect = sourceRect.width / sourceRect.height
        if !CGSizeEqualToSize(cameraSourceResolution, sourceRect.size) {
            cameraSourceResolution = sourceRect.size
        }
        
        for preview in previews  {
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
            fillWithDefaultColor()
            glEnable(GLenum(GL_BLEND))
            glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
            
            ciContext.drawImage(image, inRect: drawRect, fromRect: sourceRect)
            preview.display()
            preview.deleteDrawable()
        }
        
        delegate?.previewManagerDidOutputImageBuffer(self, imageBuffer: imageBuffer)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly)
    }
}
