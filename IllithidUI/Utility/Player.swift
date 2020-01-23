//
// Player.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import AVKit
import SwiftUI

struct Player: NSViewRepresentable {
  private let player: AVLoopedPlayer

  init(items: [AVPlayerItem]) {
    player = AVLoopedPlayer(items: items)
    player.loop()
    player.volume = 0.0
  }

  init(url: URL) {
    player = AVLoopedPlayer(url: url)
    player.loop()
    player.volume = 0.0
  }

  func makeNSView(context _: NSViewRepresentableContext<Player>) -> AVPlayerView {
    let playerView: AVPlayerView = .init()

    playerView.player = player
    playerView.allowsPictureInPicturePlayback = true
    playerView.controlsStyle = .inline
    playerView.showsFullScreenToggleButton = true
    playerView.showsSharingServiceButton = false
    playerView.updatesNowPlayingInfoCenter = false

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

    deinit {
      print("DEINIT")
    }
  }
}

// struct Player_Previews: PreviewProvider {
//  static var previews: some View {
//    Player()
//  }
// }
