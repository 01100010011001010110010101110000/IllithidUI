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

import XCDYouTubeKit

// MARK: - YouTubeView

struct YouTubeView: View {
  // MARK: Lifecycle

  init(link: URL) {
    self.link = link
    _data = .init(wrappedValue: YouTubeData())
    if link.host == "youtube.com" || link.host == "www.youtube.com" {
      identifier = (link.queryDictionary["v"] ?? "") ?? ""
    } else if link.host == "youtu.be" {
      identifier = link.path.trimmingCharacters(in: .init(charactersIn: "/"))
        .components(separatedBy: "/")
        .first ?? ""
    } else {
      identifier = ""
    }
  }

  // MARK: Internal

  let link: URL
  let identifier: String

  var body: some View {
    HStack {
      // TODO: Control full size based on which streamURL we use
      if let video = data.video, let url = video.streamURL {
        VideoPlayer(url: url, fullSize: NSSize(width: 1920, height: 1080))
          .mediaMetadataBar(metadata: video)
      }
    }
    .onAppear {
      if data.video == nil, !identifier.isEmpty {
        data.fetchData(identifier: identifier)
      }
    }
  }

  // MARK: Private

  @StateObject private var data: YouTubeData
}

// MARK: - XCDYouTubeVideo + MediaMetadataProvider

extension XCDYouTubeVideo: MediaMetadataProvider {
  var mediaTitle: String { title }

  var mediaDescription: String? { videoDescription }

  var upvotes: Int? { nil }

  var downvotes: Int? { nil }

  var hostDisplayName: String { "YouTube" }

  var views: Int { viewCount }

  var imageUrl: URL? { nil }

  var mp4Url: URL? { streamURL }

  var gifUrl: URL? { nil }

  var size: CGSize { .init(width: 1920, height: 1080) }
}

// MARK: - YouTubeData

final class YouTubeData: ObservableObject {
  let client: XCDYouTubeClient = .default()

  @Published var video: XCDYouTubeVideo? = nil

  func fetchData(identifier: String) {
    client.getVideoWithIdentifier(identifier) { video, error in
      guard error == nil else { return }

      self.video = video
    }
  }
}
