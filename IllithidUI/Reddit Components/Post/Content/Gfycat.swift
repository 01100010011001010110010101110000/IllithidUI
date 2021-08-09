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

import Foundation
import SwiftUI

import Alamofire
import Combine
import Illithid
import Ulithari

// MARK: - GfycatView

struct GfycatView: View {
  // MARK: Lifecycle

  init(id: String) {
    _data = .init(wrappedValue: GfyData(id: id))
  }

  // MARK: Internal

  @ViewBuilder var body: some View {
    VStack {
      switch data.result {
      case let .success(item):
        VideoPlayer(url: item.mp4Url!, fullSize: item.size)
          .mediaMetadataBar(metadata: item)
      case let .failure(error):
        switch error {
        case let .responseValidationFailed(reason):
          if case let .unacceptableStatusCode(code) = reason {
            if code == 404 {
              GfyNotFound()
            } else {
              GroupBox {
                Text("Retrieving the GIF failed with status code: \(code)")
              }
            }
          }
        default:
          GroupBox {
            Text("We encountered an error retrieving the GIF")
          }
        }
      default:
        EmptyView()
      }
    }
    .onAppear {
      switch data.result {
      case .success:
        break
      default:
        data.fetchGfycat()
      }
    }
    .onDisappear {
      data.cancel()
    }
  }

  // MARK: Private

  @StateObject private var data: GfyData
}

// MARK: - RedGifView

struct RedGifView: View {
  // MARK: Lifecycle

  init(id: String) {
    _data = .init(wrappedValue: GfyData(id: id))
  }

  // MARK: Internal

  @ViewBuilder var body: some View {
    VStack {
      switch data.result {
      case let .success(item):
        VideoPlayer(url: item.mp4Url!, fullSize: item.size)
          .mediaMetadataBar(metadata: item)
      case let .failure(error):
        switch error {
        case let .responseValidationFailed(reason):
          if case let .unacceptableStatusCode(code) = reason {
            if code == 404 {
              GfyNotFound()
            } else {
              GroupBox {
                Text("Retrieving the GIF failed with status code: \(code)")
              }
            }
          }
        default:
          GroupBox {
            Text("We encountered an error retrieving the GIF")
          }
        }
      default:
        EmptyView()
      }
    }
    .onAppear {
      switch data.result {
      case .success:
        break
      default:
        data.fetchRedGif()
      }
    }
    .onDisappear {
      data.cancel()
    }
  }

  // MARK: Private

  @StateObject private var data: GfyData
}

// MARK: - GfyData

final class GfyData: ObservableObject, Cancellable {
  // MARK: Lifecycle

  init(id: String) {
    self.id = id
  }

  // MARK: Internal

  @Published var result: Result<MediaMetadataProvider, AFError>? = nil
  let id: String
  var request: DataRequest?

  func fetchRedGif() {
    fetchGfy(retriever: ulithari.fetchRedGif)
  }

  func fetchGfycat() {
    fetchGfy(retriever: ulithari.fetchGfycat)
  }

  func cancel() {
    request?.cancel()
  }

  // MARK: Private

  private let ulithari: Ulithari = .shared

  private func fetchGfy(retriever: (String, DispatchQueue, @escaping (Result<MediaMetadataProvider, AFError>) -> Void) -> DataRequest) {
    request = retriever(id, .main) { [weak self] result in
      guard let self = self else { return }
      if case let .failure(error) = result {
        Illithid.shared.logger.errorMessage("Failed to fetch gfyitem \(self.id): \(error)")
      }
      self.result = result
    }
  }
}

private extension Ulithari {
  func fetchRedGif(id: String, queue: DispatchQueue = .main, completion: @escaping (Result<MediaMetadataProvider, AFError>) -> Void)
    -> DataRequest {
    fetchRedGif(id: id, queue: queue) { (result: Result<RedGfyItem, AFError>) in
      switch result {
      case let .success(item):
        completion(.success(item))
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  func fetchGfycat(id: String, queue: DispatchQueue = .main, completion: @escaping (Result<MediaMetadataProvider, AFError>) -> Void)
    -> DataRequest {
    fetchGfycat(id: id, queue: queue) { (result: Result<GfyItem, AFError>) in
      switch result {
      case let .success(item):
        completion(.success(item))
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: - GfyItem + MediaMetadataProvider

extension GfyItem: MediaMetadataProvider {
  var mediaTitle: String { title }

  var hostDisplayName: String { "Gfycat" }

  var mediaDescription: String? { gfyItemDescription }

  var upvotes: Int? { likes }

  var downvotes: Int? { dislikes }

  var imageUrl: URL? { nil }

  var mp4Url: URL? { mp4URL }

  var gifUrl: URL? { gifURL }

  var size: CGSize { .init(width: width, height: height) }
}

// MARK: - RedGfyItem + MediaMetadataProvider

extension RedGfyItem: MediaMetadataProvider {
  var mediaTitle: String { "" }

  var hostDisplayName: String { "Gfycat" }

  var mediaDescription: String? { nil }

  var upvotes: Int? { likes }

  var downvotes: Int? { nil }

  var imageUrl: URL? { nil }

  var mp4Url: URL? { contentUrls["mp4"]?.url }

  var gifUrl: URL? { contentUrls["smallGif"]?.url }

  var size: CGSize { .init(width: width, height: height) }
}

// MARK: - GfyNotFound

private struct GfyNotFound: View {
  var body: some View {
    GroupBox {
      VStack(alignment: .center) {
        Image(systemName: "play.slash.fill")
          .font(.largeTitle)
        Text("This GIF has been removed or the link was incorrect")
          .font(.title)
      }
    }
  }
}
