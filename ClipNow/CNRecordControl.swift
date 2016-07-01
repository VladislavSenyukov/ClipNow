//
//  CNRecordControl.swift
//  ClipNow
//
//  Created by ruckef on 30.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit

protocol CNRecordControlDelegate {
    func recordControlRecordClicked(control: CNRecordControl)
    func recordControlStopClicked(control: CNRecordControl)
}

class CNRecordControl: UIView {
    
    var delegate: CNRecordControlDelegate?
    var recording = false {
        didSet {
            if recording {
                prepareRecordControls()
            }
            stopRecordButton?.enabled = recording
            recordButton?.enabled = !recording
            recordButton?.hidden = recording
            counterLabel?.hidden = !recording
            circle?.hidden = !recording
        }
    }
    var recordButton: UIButton?
    var stopRecordButton: UIButton?
    var counterLabel: UILabel?
    var circle: UIView?
    var timeElapsed: UInt32 = 0
    var secondTimer: NSTimer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        backgroundColor = UIColor.clearColor()
        stopRecordButton = UIButton(type: .Custom)
        stopRecordButton?.translatesAutoresizingMaskIntoConstraints = false
        stopRecordButton?.addTarget(self, action: Selector("stopRecordingClicked"), forControlEvents: .TouchUpInside)
        addSubview(stopRecordButton!)
        stopRecordButton?.addSuperviewSizedConstraints()
        
        recordButton = UIButton(type: .Custom)
        recordButton?.translatesAutoresizingMaskIntoConstraints = false
        recordButton?.addTarget(self, action: Selector("recordButtonClicked"), forControlEvents: .TouchUpInside)
        recordButton?.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 25)
        recordButton?.setTitleColor(UIColor(red: 0.7, green: 0, blue: 0, alpha: 1), forState: .Normal)
        recordButton?.setTitle("Record", forState: .Normal)
        recordButton?.layer.cornerRadius = 10
        recordButton?.backgroundColor = UIColor(white: 0.5, alpha: 1)
        addSubview(recordButton!)
        var views: [String:AnyObject] = ["record" : recordButton!]
        var strings = ["[record(110)]", "V:[record(45)]"]
        addConstraints(strings, views: views)
        recordButton?.addConstraintCenterHorizontally()
        recordButton?.addConstraintCenterVertically()
        
        counterLabel = UILabel()
        counterLabel?.translatesAutoresizingMaskIntoConstraints = false
        counterLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 25)
        counterLabel?.textColor = UIColor(white: 0.9, alpha: 1)
        counterLabel?.text = "00:00:00"
        addSubview(counterLabel!)
        counterLabel?.addConstraintEqualHeight()
        counterLabel?.addConstraintCenterVertically()
        counterLabel?.addConstraintCenterHorizontally()
        
        circle = UIView()
        circle?.translatesAutoresizingMaskIntoConstraints = false
        circle?.backgroundColor = UIColor(red: 0.12, green: 1, blue: 0, alpha: 1)
        addSubview(circle!)
        views["circle"] = circle!
        let metrics = ["width" : 17]
        strings = ["[circle(width)]-0-[record]", "V:[circle(width)]"]
        addConstraints(strings, views: views, metrics: metrics)
        circle?.addConstraintCenterVertically()
        
        recording = false
    }
    
    override func layoutSubviews() {
        let veryWide = NSLayoutConstraint(item: counterLabel!, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 1e8)
        veryWide.priority = (counterLabel?.contentCompressionResistancePriorityForAxis(.Horizontal)
            )!
        counterLabel?.addConstraint(veryWide)
        
        super.layoutSubviews()
        
        counterLabel?.preferredMaxLayoutWidth = bounds.width
        counterLabel?.removeConstraint(veryWide)
        super.layoutSubviews()
        
        circle?.layer.cornerRadius = (circle?.bounds.width)!/2
    }
    
    func recordButtonClicked() {
        delegate?.recordControlRecordClicked(self)
        recordButton?.enabled = false
    }
    
    func stopRecordingClicked() {
        delegate?.recordControlStopClicked(self)
        stopRecordButton?.enabled = false
    }
    
    func prepareRecordControls() {
        timeElapsed = 0
        updateTimeLabel(0)
    }
    
    func startCounter() {
        secondTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("secondElapsed"), userInfo: nil, repeats: true)
    }
    
    func secondElapsed() {
        updateTimeLabel(++timeElapsed)
    }
    
    func updateTimeLabel(time:UInt32) {
        let seconds = time%60
        let minutes = (time%(60*60))/60
        let hours = time/(60*60)
        counterLabel?.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func stopCounter() {
        secondTimer?.invalidate()
    }
}
