//
//  CNCaptureManager.swift
//  ClipNow
//
//  Created by ruckef on 29.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol CNCaptureManagerDelegate {
    func captureManager(manager:CNCaptureManager, didChangeRunningStatus running: Bool)
    func captureManagerDidStartCaptureVideo(manager:CNCaptureManager)
    func captureManagerDidFinishCaptureVideo(manager:CNCaptureManager)
    func captureManagerDidStartPostProcessing(manager:CNCaptureManager)
    func captureManagerDidFinishPostProcessing(manager:CNCaptureManager, savedMediaPath: NSURL!)
}

class CNCaptureManager: NSObject, CNPreviewManagerCaptureDelegate {
    
    var delegate: CNCaptureManagerDelegate?
    var captureQueue: dispatch_queue_t = dispatch_queue_create("com.apple.captureQueue", DISPATCH_QUEUE_SERIAL)
    var isFront = false
    
    var captureSession = AVCaptureSession()
    var previewManager = CNPreviewManager()
    var currentDevice: AVCaptureDevice?
    var currentInput: AVCaptureDeviceInput?
    var currentPreviewOutput: AVCaptureVideoDataOutput?
    
    override init() {
        super.init()
        dispatch_async(captureQueue) { () -> Void in
            self.previewManager.captureDelegate = self
            self.captureSession.addObserver(self, forKeyPath: "running", options: .New, context: nil)
            self.setupSessionOutputs()
        }
    }
    
    func setupAndStart(isFront: Bool) {
        self.isFront = isFront
        dispatch_async(captureQueue) { () -> Void in
            autoreleasepool {
                self.previewManager.settingUp = true
                self.previewManager.clearPreviews()
                self.captureSession.stopRunning()
                self.setupSessionInputs(isFront)
                self.captureSession.startRunning()
                self.previewManager.settingUp = false
            }
        }
    }
    
    func setupSessionOutputs() {
        captureSession.beginConfiguration()
        
        currentPreviewOutput = AVCaptureVideoDataOutput()
        currentPreviewOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        currentPreviewOutput!.setSampleBufferDelegate(previewManager, queue: captureQueue)
        if captureSession.canAddOutput(currentPreviewOutput) {
            captureSession.addOutput(currentPreviewOutput)
        }
        
        captureSession.commitConfiguration()
    }

    func setupSessionInputs(isFrontalCamera: Bool) {
        currentDevice = nil
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            if (device.position == .Back && !isFrontalCamera) || (device.position == .Front && isFrontalCamera) {
                currentDevice = (device as! AVCaptureDevice)
            }
        }
        if let device = currentDevice {
            captureSession.beginConfiguration()
            captureSession.removeInput(currentInput)
            if let input = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    currentInput = input
                }
            }
            
            let connection = currentPreviewOutput?.connectionWithMediaType(AVMediaTypeVideo)
            if let aConn = connection {
                if aConn.supportsVideoOrientation {
                    connection?.videoOrientation = .Portrait
                }
                if aConn.supportsVideoMirroring {
                    aConn.videoMirrored = isFrontalCamera
                }
            }
        
            captureSession.commitConfiguration()
        }
    }
    
    func createPreview(frame: CGRect) -> UIView {
        return previewManager.createPreview(frame, isFront: isFront)
    }
    
    func startCaptureVideo() {
        dispatch_async(captureQueue) { () -> Void in
            if self.captureSession.running {
                self.previewManager.startCapturingPreviewVideo(self.makePathForCapturedVideo())
            }
        }
    }
    
    func stopCaptureVideo() {
        dispatch_async(captureQueue) { () -> Void in
            if self.previewManager.capturing {
                self.previewManager.stopCapturingPreviewVideo()
            }
        }
    }
    
    func previewManagerDidStartCapturingPreviewVideo(successfull: Bool) {
        if successfull {
            delegate?.captureManagerDidStartCaptureVideo(self)
        }
    }
    
    func previewManagerDidFinishCapturingPreviewVideo(path: NSURL, error: NSError?) {
        if let anError = error {
            print(anError.localizedDescription)
        }
        delegate?.captureManagerDidFinishCaptureVideo(self)
        // TODO: postProcessing
        delegate?.captureManagerDidStartPostProcessing(self)
        saveTempVideoToPhotoLibrary(path)
    }
    
    
    func saveTempVideoToPhotoLibrary(videoPath: NSURL) {
        let photosLibr = PHPhotoLibrary.sharedPhotoLibrary()
        let status = PHPhotoLibrary.authorizationStatus()
        
        let saveVideo = { () -> Void in
            var changeRequest: PHAssetChangeRequest?
            var newIdentifier: String? = nil
            photosLibr.performChanges({ () -> Void in
                changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoPath)
                if let placeholder = changeRequest?.placeholderForCreatedAsset {
                    newIdentifier = placeholder.localIdentifier
                }
            }, completionHandler: { (succes, error) -> Void in
                if succes {
                    if let anIdentif = newIdentifier {
                        let options = PHFetchOptions()
                        options.fetchLimit = 1
                        let result = PHAsset.fetchAssetsWithLocalIdentifiers([anIdentif], options: options)
                        if result.count == 1 {
                            let asset = result.objectAtIndex(0) as! PHAsset
                            self.getAssetUrl(asset, completionHandler: { (responseURL) -> Void in
                                self.delegate?.captureManagerDidFinishPostProcessing(self, savedMediaPath: responseURL)
                            })
                        }
                    }
                }
            })
        }
        
        switch status {
            case .NotDetermined:
                PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                    switch status {
                        case .Denied: break
                        case .Authorized:
                            saveVideo()
                        default: break
                    }
                })
            case .Authorized:
                saveVideo()
            default: break
        }
    }
    
    func makePathForCapturedVideo() -> NSURL {
        let outputPath = NSTemporaryDirectory() + "temp_output.mov"
        if NSFileManager.defaultManager().fileExistsAtPath(outputPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(outputPath)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        return NSURL(fileURLWithPath: outputPath)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "running" {
            if let session = object as? AVCaptureSession {
                delegate?.captureManager(self, didChangeRunningStatus: session.running)
            }
        }
    }
}

extension CNCaptureManager {
    func getAssetUrl(mPhasset : PHAsset, completionHandler : ((responseURL : NSURL?) -> Void)){
        if mPhasset.mediaType == .Image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInputWithOptions(options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [NSObject : AnyObject]) -> Void in
                completionHandler(responseURL : contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .Video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .Original
            PHImageManager.defaultManager().requestAVAssetForVideo(mPhasset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
                
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl : NSURL = urlAsset.URL
                    completionHandler(responseURL : localVideoUrl)
                } else {
                    completionHandler(responseURL : nil)
                }
            })
        }
    }
}
