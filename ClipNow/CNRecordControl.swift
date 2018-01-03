//
//  CNRecordControl.swift
//  ClipNow
//
//  Created by ruckef on 30.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit

protocol CNRecordControlDelegate {
    func recordControlRecordClicked(_ control: CNRecordControl)
    func recordControlStopClicked(_ control: CNRecordControl)
}

class CNRecordControl: UIView {
    
    var delegate: CNRecordControlDelegate?
    var recording = false {
        didSet {
            if recording {
                prepareRecordControls()
            }
            stopRecordButton?.isEnabled = recording
            recordButton?.isEnabled = !recording
            recordButton?.isHidden = recording
            counterLabel?.isHidden = !recording
            circle?.isHidden = !recording
        }
    }
    var recordButton: UIButton?
    var stopRecordButton: UIButton?
    var counterLabel: UILabel?
    var circle: UIView?
    var timeElapsed: UInt32 = 0
    var secondTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        backgroundColor = UIColor.clear
        stopRecordButton = UIButton(type: .custom)
        stopRecordButton?.translatesAutoresizingMaskIntoConstraints = false
        
        stopRecordButton?.addTarget(self, action: #selector(CNRecordControl.stopRecordingClicked), for: .touchUpInside)
        addSubview(stopRecordButton!)
        stopRecordButton?.addSuperviewSizedConstraints()
        
        recordButton = UIButton(type: .custom)
        recordButton?.translatesAutoresizingMaskIntoConstraints = false
        recordButton?.addTarget(self, action: #selector(CNRecordControl.recordButtonClicked), for: .touchUpInside)
        recordButton?.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 25)
        recordButton?.setTitleColor(UIColor(red: 0.7, green: 0, blue: 0, alpha: 1), for: UIControlState())
        recordButton?.setTitle("Record", for: UIControlState())
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
        counterLabel?.textAlignment = .center
        addSubview(counterLabel!)
        counterLabel?.addSuperviewSizedConstraints()
        
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
        super.layoutSubviews()
        circle?.layer.cornerRadius = (circle?.bounds.width)!/2
    }
    
    @objc func recordButtonClicked() {
        delegate?.recordControlRecordClicked(self)
        recordButton?.isEnabled = false
    }
    
    @objc func stopRecordingClicked() {
        delegate?.recordControlStopClicked(self)
        stopRecordButton?.isEnabled = false
    }
    
    func prepareRecordControls() {
        timeElapsed = 0
        updateTimeLabel(0)
    }
    
    func startCounter() {
        secondTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CNRecordControl.secondElapsed), userInfo: nil, repeats: true)
    }
    
    @objc func secondElapsed() {
        timeElapsed += 1
        updateTimeLabel(timeElapsed)
    }
    
    func updateTimeLabel(_ time:UInt32) {
        let seconds = time%60
        let minutes = (time%(60*60))/60
        let hours = time/(60*60)
        counterLabel?.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func stopCounter() {
        secondTimer?.invalidate()
    }
}
