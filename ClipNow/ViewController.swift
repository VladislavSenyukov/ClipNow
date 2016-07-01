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
    @IBOutlet var previewContainer: UIView?
    @IBOutlet var imageOverlay: UIImageView?
    @IBOutlet var swapButton: UIButton?
    @IBOutlet var recordControl: CNRecordControl?
    @IBOutlet var recordControlCenterX: NSLayoutConstraint?
    @IBOutlet var spinner: UIActivityIndicatorView?
    var mainPreview: UIView?
    var playerView: CNVideoPlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureManager.delegate = self
        captureManager.setupAndStart(true)
        recordControl?.delegate = self
        
        let previewBgr = captureManager.createPreview(backgroundPreview!.bounds)
        backgroundPreview?.addPreview(previewBgr)
        
        mainPreview = captureManager.createPreview(CGRect(x: 0, y: 0, width: 190, height: 190))
        previewContainer?.insertSubview(mainPreview!, belowSubview: spinner!)
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
    
    func captureManagerDidFinishCaptureVideo(manager:CNCaptureManager, savedMediaPath: NSURL!) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.spinner?.stopAnimating()
            self.playerView = CNVideoPlayerView()
            self.playerView?.translatesAutoresizingMaskIntoConstraints = false
            self.playerView?.backgroundColor = UIColor.blackColor()
            self.previewContainer?.insertSubview(self.playerView!, aboveSubview: self.mainPreview!)
            self.playerView?.addSuperviewSizedConstraints()
            self.playerView?.play(url: savedMediaPath)
            
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
        spinner?.startAnimating()
        recordControl?.stopCounter()
        captureManager.stopCaptureVideo()
    }
    
    @IBAction func swapButtonClicked() {
        let isFront = captureManager.isFront
        swapButton?.enabled = false
        captureManager.setupAndStart(!isFront)
    }
}
