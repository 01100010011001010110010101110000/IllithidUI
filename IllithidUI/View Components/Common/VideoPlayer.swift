//
// VideoPlayer.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/9/20
//

import AVKit
import Combine
import SwiftUI

extension AVPlayer: ObservableObject {}

struct VideoPlayer: View {
  @StateObject private var avPlayer: AVPlayer
  @ObservedObject var preferences: PreferencesData = .shared

  private let fullSize: NSSize

  private static func createPlayer(url: URL) -> AVPlayer {
    let player: AVPlayer = .init(url: url)
    player.isMuted = true
    return player
  }

  private var calculateSize: NSSize {
    if fullSize.height > 864 {
      let width = 864 * (fullSize.width / fullSize.height)
      return .init(width: width, height: 864)
    } else {
      return fullSize
    }
  }

  init(url: URL, fullSize: NSSize = .zero) {
    self.fullSize = fullSize
    _avPlayer = .init(wrappedValue: Self.createPlayer(url: url))
  }

  var body: some View {
    AVKit.VideoPlayer(player: avPlayer)
      .frame(width: calculateSize.width, height: calculateSize.height)
      .onDisappear {
        avPlayer.pause()
      }
  }
}
