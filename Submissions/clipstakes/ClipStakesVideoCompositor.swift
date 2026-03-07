import AVFoundation
import CoreGraphics
import Foundation
import UIKit

enum ClipStakesVideoCompositor {
    static func addText(
        to sourceURL: URL,
        text: String,
        position: ClipStakesTextPosition
    ) async -> URL? {
        await withCheckedContinuation { continuation in
            let asset = AVAsset(url: sourceURL)
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                continuation.resume(returning: nil)
                return
            }

            let composition = AVMutableComposition()
            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                continuation.resume(returning: nil)
                return
            }

            do {
                let fullRange = CMTimeRange(start: .zero, duration: asset.duration)
                try compositionVideoTrack.insertTimeRange(fullRange, of: videoTrack, at: .zero)

                if let audioTrack = asset.tracks(withMediaType: .audio).first,
                   let compositionAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                   ) {
                    try compositionAudioTrack.insertTimeRange(fullRange, of: audioTrack, at: .zero)
                }
            } catch {
                continuation.resume(returning: nil)
                return
            }

            let transform = videoTrack.preferredTransform
            let transformedSize = videoTrack.naturalSize.applying(transform)
            let renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layerInstruction]

            let videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [instruction]
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

            let parentLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: renderSize)

            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: renderSize)
            parentLayer.addSublayer(videoLayer)

            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.alignmentMode = .center
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
            textLayer.shadowOpacity = 1
            textLayer.shadowRadius = 4
            textLayer.shadowOffset = CGSize(width: 0, height: 2)
            textLayer.fontSize = max(24, renderSize.width * 0.06)
            textLayer.contentsScale = UIScreen.main.scale

            let horizontalPadding = renderSize.width * 0.08
            let textHeight = renderSize.height * 0.16

            let yOrigin: CGFloat
            switch position {
            case .top:
                yOrigin = renderSize.height * 0.12
            case .center:
                yOrigin = (renderSize.height - textHeight) / 2
            case .bottom:
                yOrigin = renderSize.height * 0.72
            }

            textLayer.frame = CGRect(
                x: horizontalPadding,
                y: yOrigin,
                width: renderSize.width - (horizontalPadding * 2),
                height: textHeight
            )

            parentLayer.addSublayer(textLayer)

            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayer: videoLayer,
                in: parentLayer
            )

            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                continuation.resume(returning: nil)
                return
            }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("clipstakes-composited-\(UUID().uuidString).mp4")

            try? FileManager.default.removeItem(at: outputURL)

            exportSession.videoComposition = videoComposition
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true

            exportSession.exportAsynchronously {
                if exportSession.status == .completed {
                    continuation.resume(returning: outputURL)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
