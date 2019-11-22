//
//  Player.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/22/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
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

    player.play()

    return playerView
  }

  func updateNSView(_: AVPlayerView, context _: NSViewRepresentableContext<Player>) {}

  final class AVLoopedPlayer: AVQueuePlayer {
    var looper: AVPlayerLooper? = nil

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
      looper = .init(player: self, templateItem: self.currentItem!)
    }
  }
}

// struct Player_Previews: PreviewProvider {
//  static var previews: some View {
//    Player()
//  }
// }
