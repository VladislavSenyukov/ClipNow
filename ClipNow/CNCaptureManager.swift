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
    func captureManagerDidSwitchCamera(_ manager:CNCaptureManager)
    func captureManagerDidStartCaptureVideo(_ manager:CNCaptureManager)
    func captureManagerDidFinishCaptureVideo(_ manager:CNCaptureManager, savedMediaPath: URL!)
}

class CNCaptureManager: NSObject {
    
    var delegate: CNCaptureManagerDelegate?
    var captureQueue: DispatchQueue = DispatchQueue(label: "com.apple.captureQueue", attributes: [])
    var isFront = false
    
    var captureSession = AVCaptureSession()
    var previewManager = CNPreviewManager()
    var videoCapturer: CNVideoCapturer?
    var videoCropper: CNVideoCropper?
    
    var currentDevice: AVCaptureDevice?
    var currentInput: AVCaptureDeviceInput?
    var audioInput: AVCaptureDeviceInput?
    var audioOutput: AVCaptureAudioDataOutput?
    var currentPreviewOutput: AVCaptureVideoDataOutput?
    let outputFileType = AVFileType.mp4
    
    override init() {
        super.init()
        captureQueue.async { () -> Void in
            self.previewManager.delegate = self
            self.setupSessionOutputs()
        }
    }
    
    func setupAndStart(_ isFront: Bool) {
        self.isFront = isFront
        captureQueue.async { () -> Void in
            self.previewManager.stopRunning()
            self.setupSessionInputs(isFront)
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            self.previewManager.startRunning()
        }
    }
    
    func setupSessionOutputs() {
        captureSession.beginConfiguration()
        
        currentPreviewOutput = AVCaptureVideoDataOutput()
        currentPreviewOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        currentPreviewOutput!.setSampleBufferDelegate(previewManager, queue: captureQueue)
        if captureSession.canAddOutput(currentPreviewOutput!) {
            captureSession.addOutput(currentPreviewOutput!)
        }
        
//        audioOutput = AVCaptureAudioDataOutput()
//        let audioCaptureQueue = DispatchQueue(label: "CN_Audio_Queue", attributes: [])
//        audioOutput?.setSampleBufferDelegate(self, queue: audioCaptureQueue)
//        if captureSession.canAddOutput(audioOutput!) {
//            captureSession.addOutput(audioOutput!)
//        }
        
        captureSession.commitConfiguration()
    }

    func setupSessionInputs(_ isFrontalCamera: Bool) {
        currentDevice = nil
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if ((device as AnyObject).position == .back && !isFrontalCamera) || ((device as AnyObject).position == .front && isFrontalCamera) {
                currentDevice = (device )
            }
        }
        
//        if audioInput == nil {
//            let audioDevices = AVCaptureDevice.devices(for: AVMediaType.audio)
//            if let audioDevice = audioDevices.first {
//                audioInput = try? AVCaptureDeviceInput(device: audioDevice )
//                if captureSession.canAddInput(audioInput!) {
//                    captureSession.addInput(audioInput!)
//                }
//            }
//        }
        
        var inputChanged = false
        if let device = currentDevice {
            captureSession.beginConfiguration()
            if let input = currentInput {
                captureSession.removeInput(input)
            }
            if let input = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    inputChanged = true
                    currentInput = input
                }
            }
            
            let connection = currentPreviewOutput?.connection(with: AVMediaType.video)
            if let aConn = connection {
                if aConn.isVideoOrientationSupported {
                    connection?.videoOrientation = .portrait
                }
                if aConn.isVideoMirroringSupported {
                    aConn.isVideoMirrored = isFrontalCamera
                }
            }
        
            captureSession.commitConfiguration()
            if inputChanged {
                delegate?.captureManagerDidSwitchCamera(self)
            }
        }
    }
    
    func createPreview(_ frame: CGRect) -> UIView {
        return previewManager.createPreview(frame, isFront: isFront)
    }
    
    func startCaptureVideo() {
        captureQueue.async { () -> Void in
            if self.captureSession.isRunning {
                self.videoCapturer = CNVideoCapturer()
                self.videoCapturer?.delegate = self
                let tempPath = URL.tempPathForFile("temp_output.mov")
                let videoWidth = CGFloat(300)
                let resolution = self.previewManager.cameraSourceResolution
                let aspect = resolution.height / resolution.width
                let videoSize = CGSize(width: videoWidth, height: ceil(videoWidth * aspect))
//                let audioSettings = self.audioOutput?.recommendedAudioSettingsForAssetWriter(writingTo: self.outputFileType) as! [String:AnyObject]
                self.videoCapturer?.startCapturingPreviewVideo(tempPath, videoSize: videoSize, audioSettings: nil, fileType: self.outputFileType.rawValue)
            }
        }
    }
    
    func stopCaptureVideo() {
        captureQueue.async { () -> Void in
            self.videoCapturer?.stopCapturingPreviewVideo()
        }
    }
}

extension CNCaptureManager : AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        videoCapturer?.appendAudioBuffer(sampleBuffer)
    }
}

extension CNCaptureManager: CNPreviewManagerDelegate {
    
    func previewManagerDidOutputImageBuffer(_ manager: CNPreviewManager, imageBuffer: CVImageBuffer) {
        videoCapturer?.appendImageBuffer(imageBuffer)
    }
}

extension CNCaptureManager: CNVideoCapturerDelegate {
    
    func videoCapturerDidStartCapturingPreviewVideo(_ capturer:CNVideoCapturer, successfull: Bool) {
        if successfull {
            delegate?.captureManagerDidStartCaptureVideo(self)
        }
    }
    
    func videoCapturerDidFinishCapturingPreviewVideo(_ capturer:CNVideoCapturer, path: URL, error: NSError?) {
        if let anError = error {
            print(anError.localizedDescription)
        }
        self.videoCapturer = nil
        CNVideoCropper.cropVideoToSquareCentered(path) { (newPath) -> () in
            self.saveTempVideoToPhotoLibrary(newPath)
        }
    }
    
    func saveTempVideoToPhotoLibrary(_ videoPath: URL) {
        let photosLibr = PHPhotoLibrary.shared()
        let status = PHPhotoLibrary.authorizationStatus()
        
        let saveVideo = { () -> Void in
            var changeRequest: PHAssetChangeRequest?
            var newIdentifier: String? = nil
            photosLibr.performChanges({ () -> Void in
                changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoPath)
                if let placeholder = changeRequest?.placeholderForCreatedAsset {
                    newIdentifier = placeholder.localIdentifier
                }
                }, completionHandler: { (succes, error) -> Void in
                    if succes {
                        if let anIdentif = newIdentifier {
                            let options = PHFetchOptions()
                            options.fetchLimit = 1
                            let result = PHAsset.fetchAssets(withLocalIdentifiers: [anIdentif], options: options)
                            if result.count == 1 {
                                let asset = result.object(at: 0) 
                                self.getAssetUrl(asset, completionHandler: { (responseURL) -> Void in
                                    self.delegate?.captureManagerDidFinishCaptureVideo(self, savedMediaPath: responseURL)
                                })
                            }
                        }
                    }
            })
        }
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                switch status {
                case .denied: break
                case .authorized:
                    saveVideo()
                default: break
                }
            })
        case .authorized:
            saveVideo()
        default: break
        }
    }
}

extension CNCaptureManager {

    func getAssetUrl(_ mPhasset : PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable: Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable: Any]?) -> Void in
                
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl : URL = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}

extension URL {
    static func tempPathForFile(_ name: String) -> URL {
        let outputPath = NSTemporaryDirectory() + name
        if FileManager.default.fileExists(atPath: outputPath) {
            do {
                try FileManager.default.removeItem(atPath: outputPath)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        return URL(fileURLWithPath: outputPath)
    }
}
