//
// Player.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 1/22/20
//

import AVKit
import SwiftUI

struct Player: NSViewRepresentable {
  @ObservedObject private var playerData: PlayerData

  init(url: URL) {
    playerData = PlayerData(url: url)
  }

  func makeNSView(context _: NSViewRepresentableContext<Player>) -> AVPlayerView {
    let playerView: AVPlayerView = .init()

    playerView.player = playerData.player
    playerView.allowsPictureInPicturePlayback = true
    playerView.controlsStyle = .inline
    playerView.showsFullScreenToggleButton = true
    playerView.showsSharingServiceButton = false
    playerView.updatesNowPlayingInfoCenter = false

    return playerView
  }

  func updateNSView(_: AVPlayerView, context _: NSViewRepresentableContext<Player>) {}
}

final class PlayerData: ObservableObject {
  fileprivate let player: AVQueuePlayer
  fileprivate let looper: AVPlayerLooper

  init(url: URL) {
    player = AVQueuePlayer(url: url)
    looper = AVPlayerLooper(player: player, templateItem: player.currentItem!)
    player.volume = 0.0
  }
}

// struct Player_Previews: PreviewProvider {
//  static var previews: some View {
//    Player()
//  }
// }
