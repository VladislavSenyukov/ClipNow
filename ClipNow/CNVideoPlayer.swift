//
//  CNVideoPlayer.swift
//  ClipNow
//
//  Created by ruckef on 02.07.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import AVFoundation

class CNVideoPlayerView: UIView {
    
    var url: NSURL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var readyToPlayCompletion: (()->())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !CGRectEqualToRect(bounds, playerLayer!.frame) {
            playerLayer!.frame = bounds
        }
    }
    
    func play(url url:NSURL, readyToPlayHandler: ()->()) {
        self.url = url
        self.readyToPlayCompletion = readyToPlayHandler
        AVPlayerItemDidPlayToEndTimeNotification
        player = AVPlayer(URL: self.url!)
        player?.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playingDidFinish"), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        playerLayer = AVPlayerLayer(player: player)
        layer.insertSublayer(playerLayer!, atIndex: 0)
    }
    
    func playingDidFinish() {
        // create an infinite play loop
        player?.seekToTime(kCMTimeZero)
        player?.play()
    }
    
    func stop() {
        player?.pause()
        player?.removeObserver(self, forKeyPath: "status")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            let status = player!.status
            switch status {
            case .ReadyToPlay:
                player?.play()
                readyToPlayCompletion!()
            default:
                print("Cannot play the item \(url) status: \(status)")
            }
        }
    }
}
