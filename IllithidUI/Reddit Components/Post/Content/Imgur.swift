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

import Alamofire
import Combine
import Illithid
import SDWebImageSwiftUI
import Ulithari

// MARK: - ImgurView

struct ImgurView: View {
  // MARK: Lifecycle

  init(link: URL) {
    imgurData = .init(link)
  }

  // MARK: Internal

  @ObservedObject var imgurData: ImgurData

  var body: some View {
    Group {
      if imgurData.images.isEmpty {
        Rectangle()
          .opacity(0)
      } else if imgurData.images.count == 1, let image = imgurData.images.first {
        if image.animated {
          VideoPlayer(url: image.mp4!, fullSize: .init(width: image.width, height: image.height))
            .mediaMetadataBar(metadata: image)
        } else {
          ImagePostPreview(url: image.link, size: NSSize(width: image.width, height: image.height))
            .mediaMetadataBar(metadata: image)
        }
      } else {
        PagedView(data: imgurData.images) { image in
          if image.animated {
            VideoPlayer(url: image.mp4!, fullSize: .init(width: image.width, height: image.height))
              .mediaMetadataBar(metadata: image)
          } else {
            ImagePostPreview(url: image.link,
                             size: NSSize(width: image.width, height: image.height),
                             enableMediaPanel: false)
              .mediaMetadataBar(metadata: image)
          }
        }
      }
    }
    .onAppear {
      guard imgurData.images.isEmpty else { return }
      imgurData.loadContent()
    }
  }
}

// MARK: - ImgurImage + MediaMetadataProvider

extension ImgurImage: MediaMetadataProvider {
  var mediaTitle: String {
    title ?? ""
  }

  var mediaDescription: String? {
    dataDescription
  }

  var upvotes: Int? {
    vote
  }

  var downvotes: Int? {
    nil
  }

  var hostDisplayName: String {
    "Imgur"
  }
}

// MARK: - ImgurData

final class ImgurData: ObservableObject, Cancellable {
  // MARK: Lifecycle

  init(_ link: URL) {
    self.link = link
  }

  // MARK: Internal

  @Published var images: [ImgurImage] = []

  let link: URL

  func loadContent() {
    switch ulithari.imgurLinkType(link) {
    case let .album(id):
      request = ulithari.fetchImgurAlbum(id: id) { result in
        switch result {
        case let .success(album):
          self.images.append(contentsOf: album.images)
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Error fetching imgur album with id \(id): \(error)")
        }
      }
    case .gallery:
      // TODO: - implement gallery support
      return
    case let .image(id):
      request = ulithari.fetchImgurImage(id: id) { result in
        _ = result.map { self.images.append($0) }
      }
    case nil:
      // Invalid link
      return
    }
  }

  func cancel() {
    request?.cancel()
  }

  // MARK: Private

  private let ulithari: Ulithari = .shared
  private var request: DataRequest?
}
