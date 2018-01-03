//
//  CNVideoCropper.swift
//  ClipNow
//
//  Created by ruckef on 01.07.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import AVFoundation

class CNVideoCropper {
    static func cropVideoToSquareCentered(_ path: URL, completion: @escaping (_ newPath: URL) -> ()) {
        let asset = AVAsset(url: path)
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else {
            //TODO throw error
            return
        }
        
        let composition = AVMutableVideoComposition()
        let frameDuration = track.minFrameDuration
        composition.frameDuration = frameDuration
        let trackSize = track.naturalSize
        composition.renderSize = CGSize(width: trackSize.width, height: trackSize.width)
        
        let compositionInstruction = AVMutableVideoCompositionInstruction()
        let timeRange = track.timeRange
        compositionInstruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = CGAffineTransform(translationX: 0, y: -(trackSize.height-trackSize.width)/2)
        layerInstruction.setTransform(transform, at: kCMTimeZero)
        
        compositionInstruction.layerInstructions = [layerInstruction]
        composition.instructions = [compositionInstruction]
        
        let tempPath = URL.tempPathForFile("temp_cropped.mov")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            //TODO throw error
            return
        }
        exporter.videoComposition = composition
        exporter.outputURL = tempPath
        exporter.outputFileType = AVFileType.mp4
        exporter.exportAsynchronously { () -> Void in
            completion(tempPath)
            
        }
    }
}
