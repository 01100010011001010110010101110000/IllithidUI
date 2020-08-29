// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

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
