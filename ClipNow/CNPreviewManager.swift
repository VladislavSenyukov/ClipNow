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
    func previewManagerDidOutputImageBuffer(_ manager: CNPreviewManager, imageBuffer: CVImageBuffer)
}

class CNGLPreview: GLKView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
}

class CNPreviewManager : NSObject {
    
    var delegate: CNPreviewManagerDelegate?
    var previews = [CNGLPreview]()
    let glContext: EAGLContext
    let ciContext: CIContext
    var cameraSourceResolution: CGSize = CGSize.zero
    var scale = UIScreen.main.scale
    var settingUp = false
    
    override init() {
        glContext = EAGLContext(api: .openGLES3)!
        ciContext = CIContext(eaglContext: glContext, options: [kCIContextWorkingColorSpace : NSNull()])
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
        if EAGLContext.current() != glContext {
            EAGLContext.setCurrent(glContext)
        }
        for preview in previews  {
            preview.bindDrawable()
            fillWithDefaultColor()
            preview.display()
            preview.deleteDrawable()
        }
    }
    
    func createPreview(_ frame: CGRect, isFront: Bool) -> UIView {
        let preview = CNGLPreview(frame: frame, context: glContext)
        previews.append(preview)
        return preview
    }
}

extension CNPreviewManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if settingUp {
            return
        }
        
        if EAGLContext.current() != glContext {
            EAGLContext.setCurrent(glContext)
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
        let image = CIImage(cvPixelBuffer: imageBuffer, options: nil)
        var sourceRect = image.extent
        let sourceAspect = sourceRect.width / sourceRect.height
        if !cameraSourceResolution.equalTo(sourceRect.size) {
            cameraSourceResolution = sourceRect.size
        }
        
        DispatchQueue.main.async {
            for preview in self.previews  {
                var drawRect = preview.bounds
                drawRect.size.width *= self.scale
                drawRect.size.height *= self.scale
                let drawAspect = drawRect.width / drawRect.height
                if drawAspect < sourceAspect {
                    sourceRect.origin.x += (sourceRect.width - sourceRect.height * drawAspect) / 2
                    sourceRect.size.width = sourceRect.size.height * drawAspect
                } else {
                    sourceRect.origin.y += (sourceRect.height - sourceRect.width / drawAspect) / 2
                    sourceRect.size.height = sourceRect.width / drawAspect
                }
                
                preview.bindDrawable()
                self.fillWithDefaultColor()
                glEnable(GLenum(GL_BLEND))
                glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
                
                self.ciContext.draw(image, in: drawRect, from: sourceRect)
                preview.display()
                preview.deleteDrawable()
            }
        }

        delegate?.previewManagerDidOutputImageBuffer(self, imageBuffer: imageBuffer)
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
    }
}
