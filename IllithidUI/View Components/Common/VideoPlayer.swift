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

// MARK: - AVPlayer + ObservableObject

extension AVPlayer: ObservableObject {}

// MARK: - VideoPlayer

struct VideoPlayer: View {
  // MARK: Lifecycle

  init(url: URL, fullSize: NSSize = .zero) {
    self.fullSize = fullSize
    _avPlayer = .init(wrappedValue: Self.createPlayer(url: url))
  }

  // MARK: Internal

  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    AVKit.VideoPlayer(player: avPlayer)
      .frame(width: 480, height: 360)
      .onDisappear {
        avPlayer.pause()
      }
      .onTapGesture {
        // TODO: Use a separate player for the media panel
        avPlayer.pause()
        avPlayer.seek(to: .zero)
        WindowManager.shared.showMediaPanel(aspectRatio: fullSize) {
          AVKit.VideoPlayer(player: avPlayer)
            .mediaPanelOverlay(size: fullSize, resizable: false)
        }
      }
  }

  // MARK: Private

  @StateObject private var avPlayer: AVPlayer
  private let fullSize: NSSize

  private var calculateSize: NSSize {
    if fullSize.height > 864 {
      let width = 864 * (fullSize.width / fullSize.height)
      return .init(width: width, height: 864)
    } else {
      return fullSize
    }
  }

  private static func createPlayer(url: URL) -> AVPlayer {
    let player: AVPlayer = .init(url: url)
    player.isMuted = true
    return player
  }
}
