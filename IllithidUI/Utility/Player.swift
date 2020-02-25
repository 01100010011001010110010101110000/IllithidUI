//
// Player.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 1/22/20
//

import AVKit
import Combine
import SwiftUI

struct Player: NSViewRepresentable {
  @ObservedObject private var playerData: PlayerData

  init(url: URL) {
    playerData = PlayerData(url: url)
  }

  init(_ playerData: PlayerData) {
    self.playerData = playerData
  }

  func makeNSView(context _: NSViewRepresentableContext<Player>) -> AVPlayerView {
    let playerView: AVPlayerView = .init()

    playerView.player = playerData.player
    playerView.allowsPictureInPicturePlayback = true
    playerView.controlsStyle = .inline
    playerView.showsFullScreenToggleButton = true
    playerView.showsSharingServiceButton = false
    playerView.updatesNowPlayingInfoCenter = false
    playerView.videoGravity = .resizeAspect
    playerView.autoresizingMask = [.height, .width]

    return playerView
  }

  func updateNSView(_: AVPlayerView, context _: NSViewRepresentableContext<Player>) {}
}

final class PlayerData: ObservableObject {
  let player: AVPlayer
  private var cancelToken: AnyCancellable?

  init(url: URL) {
    player = AVPlayer(url: url)
    player.volume = 0.0
    cancelToken = NotificationCenter.default
      .publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem!)
      .receive(on: RunLoop.main)
      .sink { [weak self] notification in
        self?.player.seek(to: .zero)
        self?.player.play()
    }
  }

  deinit {
    cancelToken?.cancel()
  }
}

// struct Player_Previews: PreviewProvider {
//  static var previews: some View {
//    Player()
//  }
// }
