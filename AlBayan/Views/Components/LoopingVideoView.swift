//
//  LoopingVideoView.swift
//  AlBayan
//
//  Silent, seamless looping video background (premium-art-sunni doc 04-B). Uses AVPlayerLooper
//  on an AVQueuePlayer (muted, resize-aspect-fill). The audio session is set to .ambient +
//  .mixWithOthers so the loop NEVER interrupts the user's own audio (recitation, music).
//  `isActive` drives play/pause - bind it to page visibility + app foreground state. Callers
//  should check `Bundle.main.url(forResource:withExtension:)` first and fall back to a still if
//  the asset is missing (this view renders transparent when it can't load).
//

import SwiftUI
import AVFoundation

struct LoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let fileExtension: String
    var isActive: Bool

    func makeUIView(context: Context) -> LoopingVideoUIView {
        LoopingVideoUIView(resourceName: resourceName, fileExtension: fileExtension)
    }

    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {
        uiView.setActive(isActive)
    }

    static func dismantleUIView(_ uiView: LoopingVideoUIView, coordinator: Coordinator) {
        uiView.teardown()
    }
}

final class LoopingVideoUIView: UIView {
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    init(resourceName: String, fileExtension: String) {
        super.init(frame: .zero)
        backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            return   // No asset -> stays transparent; the caller's still background shows through.
        }

        // .ambient + .mixWithOthers: obeys the ringer switch and never interrupts the user's audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        let looper = AVPlayerLooper(player: player, templateItem: item)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)

        queuePlayer = player
        self.looper = looper
        playerLayer = layer
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func setActive(_ active: Bool) {
        guard let queuePlayer else { return }
        if active {
            try? AVAudioSession.sharedInstance().setActive(true)
            queuePlayer.play()
        } else {
            queuePlayer.pause()
        }
    }

    func teardown() {
        queuePlayer?.pause()
        looper?.disableLooping()
        playerLayer?.removeFromSuperlayer()
        queuePlayer = nil
        looper = nil
        playerLayer = nil
    }
}
