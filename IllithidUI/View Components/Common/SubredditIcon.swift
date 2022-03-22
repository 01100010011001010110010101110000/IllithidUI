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

import SwiftUI

import Illithid
import SDWebImageSwiftUI

// MARK: - SubredditIcon

struct SubredditIcon: View {
  // MARK: Lifecycle

  init(subreddit: Subreddit) {
    imageUrl = subreddit.communityIcon ?? subreddit.iconImg
    displayName = subreddit.displayName
    displayLetter = String(subreddit.displayName.first!.uppercased())
  }

  init(subreddit: SubscribedSubreddit) {
    imageUrl = subreddit.iconImage
    displayName = subreddit.displayName
    displayLetter = String(subreddit.displayName.first!.uppercased())
  }

  init(multireddit: Multireddit) {
    imageUrl = multireddit.iconUrl
    displayName = multireddit.displayName
    displayLetter = String(multireddit.displayName.first!.uppercased())
  }

  // MARK: Internal

  var body: some View {
    if let imageUrl = imageUrl {
      WebImage(url: imageUrl)
        .renderingMode(.original)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .clipShape(Circle())
    } else {
      Circle()
        .foregroundColor(displayName.toColor())
        // TODO: Resize text depending on the size of the circle
        .overlay(Text(displayLetter))
    }
  }

  // MARK: Private

  private static let defaultIconPrefix = "custom_feed_default"

  private let imageUrl: URL?
  private let displayName: String
  private let displayLetter: String
}

private extension String {
  /// Generates a deterministic color from a given string
  /// - Note: Taken from the [string-to-color](https://github.com/Gustu/string-to-color) JS package with slight modifications
  func toColor() -> Color {
    let seed: UInt = 16_777_215
    let factor: UInt = 49_979_693

    guard !isEmpty else { return Color.gray }
    var b: UInt = 1
    var d: UInt = 0
    var f: UInt = 1

    for character in utf8 {
      let codePoint = UInt(character)
      if codePoint > d {
        d = codePoint
      }
      f = UInt(seed / d)
      b = (b + codePoint * f * factor) % seed
    }
    let hex = (b * UInt(count)) % seed
    var red, green, blue: UInt
    (red, green, blue) = (hex >> 16, hex >> 8 & 0xFF, hex & 0xFF)
    return Color(.sRGB,
                 red: Double(red) / 255,
                 green: Double(green) / 255,
                 blue: Double(blue) / 255)
  }
}

// struct SubredditIconView_Previews: PreviewProvider {
//  static var previews: some View {
//    SubredditIconView()
//  }
// }
