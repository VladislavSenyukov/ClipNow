//
//  CNVideoPlayer.swift
//  ClipNow
//
//  Created by ruckef on 02.07.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import AVFoundation

class CNVideoPlayerView: UIView {
    
    var url: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var readyToPlayCompletion: (()->())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !bounds.equalTo(playerLayer!.frame) {
            playerLayer!.frame = bounds
        }
    }
    
    func play(url:URL, readyToPlayHandler: @escaping ()->()) {
        self.url = url
        self.readyToPlayCompletion = readyToPlayHandler
        player = AVPlayer(url: self.url!)
        player?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CNVideoPlayerView.playingDidFinish), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        playerLayer = AVPlayerLayer(player: player)
        layer.insertSublayer(playerLayer!, at: 0)
    }
    
    @objc func playingDidFinish() {
        // create an infinite play loop
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    func stop() {
        player?.pause()
        player?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = player!.status
            switch status {
            case .readyToPlay:
                player?.play()
                readyToPlayCompletion!()
            default:
                print("Cannot play the item \(String(describing: url)) status: \(status)")
            }
        }
    }
}
