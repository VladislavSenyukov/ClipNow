//
//  ViewController.swift
//  ClipNow
//
//  Created by ruckef on 29.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit


class ViewController: UIViewController, CNCaptureManagerDelegate, CNRecordControlDelegate {

    var captureManager = CNCaptureManager()
    @IBOutlet var backgroundPreview: CNVideoPreviewBlurred?
    @IBOutlet var imageOverlay: UIImageView?
    @IBOutlet var swapButton: UIButton?
    @IBOutlet var recordControl: CNRecordControl?
    @IBOutlet var recordControlCenterX: NSLayoutConstraint?
    var mainPreview: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureManager.delegate = self
        captureManager.setupAndStart(true)
        recordControl?.delegate = self
        
        let previewBgr = captureManager.createPreview(backgroundPreview!.bounds)
        backgroundPreview?.addPreview(previewBgr)
        
        mainPreview = captureManager.createPreview(CGRect(x: 0, y: 0, width: 190, height: 190))
        view.insertSubview(mainPreview!, belowSubview: imageOverlay!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainPreview?.frame.origin.x = (view.bounds.width - mainPreview!.bounds.width)/2
        mainPreview?.frame.origin.y = (view.bounds.height - mainPreview!.bounds.height)/2
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        recordControlCenterX?.constant = (mainPreview?.frame.height)!
    }
    
    func captureManager(manager: CNCaptureManager, didChangeRunningStatus running: Bool) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.swapButton?.enabled = running
            if running {
                let imageName = manager.isFront ? "ic_camera_rear_white" : "ic_camera_front_white"
                self.swapButton?.setBackgroundImage(UIImage(named: imageName), forState: .Normal)
            }
        }
    }

//
//      Capture video delegates
//
    
    func captureManagerDidStartCaptureVideo(manager: CNCaptureManager) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.recordControl?.startCounter()
        }
    }
    
    func captureManagerDidFinishCaptureVideo(manager: CNCaptureManager) {
        //TODO add loading preview spinners
    }
    
    func captureManagerDidStartPostProcessing(manager: CNCaptureManager) {
        
    }
    
    func captureManagerDidFinishPostProcessing(manager: CNCaptureManager, savedMediaPath: NSURL!) {
        // TODO start a video player on preview
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.recordControl?.recording = false
            self.swapButton?.enabled = true
        }
    }
    
//      ---------------------
//      -------------
//
    
    func recordControlRecordClicked(control: CNRecordControl) {
        recordControl?.recording = true
        swapButton?.enabled = false
        captureManager.startCaptureVideo()
    }

    func recordControlStopClicked(control: CNRecordControl) {
        recordControl?.stopCounter()
        captureManager.stopCaptureVideo()
    }
    
    @IBAction func swapButtonClicked() {
        let isFront = captureManager.isFront
        swapButton?.enabled = false
        captureManager.setupAndStart(!isFront)
    }
}
