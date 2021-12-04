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

import Combine
import Foundation
import LinkPresentation
import os.log
import SwiftUI

import Alamofire
import Kanna
import SDWebImageSwiftUI

// MARK: - LinkPreview

struct LinkPreview: View {
  // MARK: Lifecycle

  init(link: URL, isNsfw: Bool = false, thumbnailUrl: URL? = nil) {
    previewData = .init(link: link)
    self.isNsfw = isNsfw
    self.thumbnailUrl = thumbnailUrl
    _showingPreview = .init(initialValue: false)
    _hover = .init(initialValue: false)
  }

  // MARK: Internal

  @ObservedObject var previewData: LinkPreviewData
  let isNsfw: Bool
  let thumbnailUrl: URL?

  var body: some View {
    VStack(spacing: 0.0) {
      Rectangle()
        .frame(height: 336)
        .foregroundColor(Color(.darkGray))
        .overlay {
          if let url = thumbnailUrl ?? previewData.previewImageUrl {
            WebImage(url: url, context: [.imageTransformer:
                SDImageResizingTransformer(size: CGSize(width: 512, height: 336), scaleMode: .aspectFill)])
              .conditionalModifier(isNsfw, NsfwBlurModifier())
          } else {
            Image(systemName: "link")
              .font(.system(size: 60))
              .foregroundColor(.blue)
          }
        }

      LinkBar(iconIsScaled: $hover, link: previewData.link)
        .popover(isPresented: $showingPreview) {
          WebPreviewPopover(showingPreview: $showingPreview,
                            link: previewData.link)
        }
    }
    .frame(width: 512)
    .onTapGesture {
      openLink(previewData.link)
    }
    .onLongPressGesture(minimumDuration: 0.1) {
      self.showingPreview = true
    }
    .onHover { entered in
      withAnimation(.easeInOut(duration: 0.7)) {
        self.hover = entered
      }
    }
    .background(Color(.controlBackgroundColor))
    .roundedBorder(style: Color(.darkGray), width: 2.0)
    .onAppear {
      if thumbnailUrl == nil && previewData.previewImageUrl == nil {
        previewData.loadMetadata()
      }
    }
    .onDisappear {
      previewData.cancel()
    }
  }

  // MARK: Private

  @State private var showingPreview: Bool
  @State private var hover: Bool
}

// MARK: - LinkPreviewData

final class LinkPreviewData: ObservableObject {
  // MARK: Lifecycle

  init(link: URL) {
    self.link = link
  }

  // MARK: Internal

  // TODO: Replace this with injection from higher in the view hierarchy
  static let session = Session()

  @Published var previewImageUrl: URL?

  let link: URL

  func loadMetadata() {
    request = Self.session.request(link)
      .validate()
      .cacheResponse(using: ResponseCacher.cache)
      .responseString(queue: Self.queue, encoding: .utf8) { [weak self] response in
        guard let self = self else { return }

        switch response.result {
        case let .success(html):
          // Fetch link's HTML document
          do {
            let document = try HTML(html: html, encoding: .utf8)

            // Fetch page's preview image link from meta tags
            let url = document.css("meta")
              .first { $0["property"] == "og:image" }
              .flatMap { $0["content"] }
              .flatMap { URL(string: $0) }
            DispatchQueue.main.async {
              self.previewImageUrl = url
            }
          } catch {
            print("Error parsing HTML from \(self.link): \(error)")
          }
        case let .failure(error):
          print("Error fetching HTML from \(self.link): \(error)")
        }
      }
  }

  func cancel() {
    request?.cancel()
  }

  // MARK: Private

  private static let queue = DispatchQueue(label: "com.flayware.IllithidUI.LinkPreview")

  private var request: DataRequest?

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.LinkPreview", category: .pointsOfInterest)
}

// MARK: - LinkPreview_Previews

struct LinkPreview_Previews: PreviewProvider {
  static let urls: [URL] = [
    URL(string: "https://www.theguardian.com/technology/2020/jan/21/amazon-boss-jeff-bezoss-phone-hacked-by-saudi-crown-prince")!,
  ]

  static var previews: some View {
    ForEach(urls, id: \.absoluteString) { url in
      LinkPreview(link: url)
    }
  }
}

// MARK: - LinkBar

struct LinkBar: View {
  // MARK: Lifecycle

  init(iconIsScaled: Binding<Bool>, icon: Image? = nil, link: URL) {
    _scaleIcon = iconIsScaled
    self.link = link
    iconOverride = icon
  }

  // MARK: Internal

  @ObservedObject var preferences: PreferencesData = .shared
  @Binding var scaleIcon: Bool

  let link: URL
  let iconOverride: Image?

  var body: some View {
    HStack(alignment: .center) {
      icon
        .resizable()
        .foregroundColor(.white)
        .frame(width: 24, height: 24)
        .padding(.leading, 4.0)
        .scaleEffect(scaleIcon ? 1.3 : 1.0)
      Rectangle()
        .fill(Color(.darkGray))
        .frame(width: 2, height: 24)
      Text(link.host ?? "")
        + Text(link.path)
        .foregroundColor(.secondary)
      Spacer()
    }
    .onTapGesture {
      openLink(link)
    }
    .padding(4)
    .frame(maxHeight: 32, alignment: .leading)
  }

  // MARK: Private

  private var icon: Image {
    if iconOverride != nil { return iconOverride! }
    else {
      return preferences.browser.icon() != nil ?
        Image(nsImage: preferences.browser.icon()!) : Image(systemName: "safari")
    }
  }
}

// MARK: - WebPreviewPopover

private struct WebPreviewPopover: View {
  @Environment(\.hostingWindow) var hostingWindow
  @Binding var showingPreview: Bool
  let link: URL

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: {
          openLink(link)
          showingPreview = false
        }, label: {
          Text("Open")
        })
        SharingButton(items: [link], edge: .maxX)
        Spacer()
      }
      .padding(5)
      WebView(url: link)
    }
    .frame(width: (hostingWindow.frame?.width ?? 800) / 1.3333,
           height: (hostingWindow.screen??.frame.height ?? 1200) / 1.3333)
  }
}
