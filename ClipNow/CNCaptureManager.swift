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
    func captureManagerDidSwitchCamera(manager:CNCaptureManager)
    func captureManagerDidStartCaptureVideo(manager:CNCaptureManager)
    func captureManagerDidFinishCaptureVideo(manager:CNCaptureManager, savedMediaPath: NSURL!)
}

class CNCaptureManager: NSObject {
    
    var delegate: CNCaptureManagerDelegate?
    var captureQueue: dispatch_queue_t = dispatch_queue_create("com.apple.captureQueue", DISPATCH_QUEUE_SERIAL)
    var isFront = false
    
    var captureSession = AVCaptureSession()
    var previewManager = CNPreviewManager()
    var videoCapturer: CNVideoCapturer?
    var videoCropper: CNVideoCropper?
    
    var currentDevice: AVCaptureDevice?
    var currentInput: AVCaptureDeviceInput?
    var currentPreviewOutput: AVCaptureVideoDataOutput?
    
    override init() {
        super.init()
        dispatch_async(captureQueue) { () -> Void in
            self.previewManager.delegate = self
            self.setupSessionOutputs()
        }
    }
    
    func setupAndStart(isFront: Bool) {
        self.isFront = isFront
        dispatch_async(captureQueue) { () -> Void in
            self.previewManager.stopRunning()
            self.setupSessionInputs(isFront)
            if !self.captureSession.running {
                self.captureSession.startRunning()
            }
            self.previewManager.startRunning()
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
        var inputChanged = false
        if let device = currentDevice {
            captureSession.beginConfiguration()
            captureSession.removeInput(currentInput)
            if let input = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    inputChanged = true
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
            if inputChanged {
                delegate?.captureManagerDidSwitchCamera(self)
            }
        }
    }
    
    func createPreview(frame: CGRect) -> UIView {
        return previewManager.createPreview(frame, isFront: isFront)
    }
    
    func startCaptureVideo() {
        dispatch_async(captureQueue) { () -> Void in
            if self.captureSession.running {
                self.videoCapturer = CNVideoCapturer()
                self.videoCapturer?.delegate = self
                let tempPath = NSURL.tempPathForFile("temp_output.mov")
                let videoWidth = CGFloat(300)
                let resolution = self.previewManager.cameraSourceResolution
                let aspect = resolution.height / resolution.width
                let videoSize = CGSize(width: videoWidth, height: ceil(videoWidth * aspect))
                self.videoCapturer?.startCapturingPreviewVideo(tempPath, videoSize: videoSize)
            }
        }
    }
    
    func stopCaptureVideo() {
        dispatch_async(captureQueue) { () -> Void in
            self.videoCapturer?.stopCapturingPreviewVideo()
        }
    }
}

extension CNCaptureManager: CNPreviewManagerDelegate {
    
    func previewManagerDidOutputImageBuffer(manager: CNPreviewManager, imageBuffer: CVImageBuffer) {
        videoCapturer?.appendImageBuffer(imageBuffer)
    }
}

extension CNCaptureManager: CNVideoCapturerDelegate {
    
    func videoCapturerDidStartCapturingPreviewVideo(capturer:CNVideoCapturer, successfull: Bool) {
        if successfull {
            delegate?.captureManagerDidStartCaptureVideo(self)
        }
    }
    
    func videoCapturerDidFinishCapturingPreviewVideo(capturer:CNVideoCapturer, path: NSURL, error: NSError?) {
        if let anError = error {
            print(anError.localizedDescription)
        }
        self.videoCapturer = nil
        CNVideoCropper.cropVideoToSquareCentered(path) { (newPath) -> () in
            self.saveTempVideoToPhotoLibrary(newPath)
        }
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
                                    self.delegate?.captureManagerDidFinishCaptureVideo(self, savedMediaPath: responseURL)
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

extension NSURL {
    static func tempPathForFile(name: String) -> NSURL {
        let outputPath = NSTemporaryDirectory() + name
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
}
