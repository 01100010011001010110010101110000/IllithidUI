//
// Player.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import AVKit
import SwiftUI

struct Player: NSViewRepresentable {
  let url: URL

  func makeNSView(context _: NSViewRepresentableContext<Player>) -> AVPlayerView {
    let playerView: AVPlayerView = .init()
    let player = AVLoopedPlayer(url: url)
    player.loop()

    playerView.player = player
    playerView.allowsPictureInPicturePlayback = true
    playerView.controlsStyle = .inline
    playerView.showsFullScreenToggleButton = true
    playerView.showsSharingServiceButton = false
    playerView.updatesNowPlayingInfoCenter = false
    player.volume = 0.0

    // TODO: Make autoplay a user preference
//    player.play()

    return playerView
  }

  func updateNSView(_: AVPlayerView, context _: NSViewRepresentableContext<Player>) {}

  final class AVLoopedPlayer: AVQueuePlayer {
    var looper: AVPlayerLooper?

    override init() {
      super.init()
    }

    override init(items: [AVPlayerItem]) {
      super.init(items: items)
    }

    override init(url URL: URL) {
      super.init(url: URL)
    }

    override init(playerItem item: AVPlayerItem?) {
      super.init(playerItem: item)
    }

    func loop() {
      looper = .init(player: self, templateItem: currentItem!)
    }
  }
}

// struct Player_Previews: PreviewProvider {
//  static var previews: some View {
//    Player()
//  }
// }
