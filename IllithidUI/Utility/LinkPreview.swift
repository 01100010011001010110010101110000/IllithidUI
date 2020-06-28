//
// LinkPreview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import Combine
import Foundation
import LinkPresentation
import os.log
import SwiftUI

import Alamofire
import Kanna
import SDWebImageSwiftUI

struct LinkPreview: View {
  @ObservedObject var previewData: LinkPreviewData
  @State private var showingPreview: Bool
  @State private var hover: Bool

  let isNsfw: Bool

  init(link: URL, isNsfw: Bool = false) {
    previewData = .init(link: link)
    self.isNsfw = isNsfw
    _showingPreview = .init(initialValue: false)
    _hover = .init(initialValue: false)
  }

  var body: some View {
    VStack(spacing: 0.0) {
      previewData.previewImageUrl.map { url in
        WebImage(url: url, context: [.imageTransformer:
            SDImageResizingTransformer(size: CGSize(width: 512, height: 336), scaleMode: .aspectFill)])
          .conditionalModifier(isNsfw, NsfwBlurModifier())
      }

      LinkBar(iconIsScaled: $hover, link: previewData.link)
        .popover(isPresented: $showingPreview) {
          WebPreviewPopover(showingPreview: self.$showingPreview,
                            link: self.previewData.link)
        }
    }
    .onHover { entered in
      withAnimation(.easeInOut(duration: 0.7)) {
        self.hover = entered
      }
    }
    .onTapGesture {
      openLink(self.previewData.link)
    }
    .onLongPressGesture(minimumDuration: 0.3) {
      self.showingPreview = true
    }
    .frame(width: 512)
    .background(Color(.controlBackgroundColor))
    .modifier(RoundedBorder(style: Color(.darkGray), cornerRadius: 8.0, width: 2.0))
    .onAppear {
      if self.previewData.previewImageUrl == nil {
        self.previewData.loadMetadata()
      }
    }
    .onDisappear {
      self.previewData.cancel()
    }
  }
}

final class LinkPreviewData: ObservableObject {
  // TODO: Replace this with injection from higher in the view hierarchy
  static let session = Session()
  @Published var previewImageUrl: URL?

  let link: URL
  private var request: DataRequest?

  init(link: URL) {
    self.link = link
  }

  private static let queue = DispatchQueue(label: "com.flayware.IllithidUI.LinkPreview")
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.LinkPreview", category: .pointsOfInterest)

  func loadMetadata() {
    request = Self.session.request(link)
      .validate()
      .cacheResponse(using: ResponseCacher.cache)
      .responseString(queue: Self.queue, encoding: .utf8) { response in
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
            print("Error parsing HTML: \(error)")
          }
        case let .failure(error):
          print("Error fetching HTML: \(error)")
        }
      }
  }

  func cancel() {
    request?.cancel()
  }
}

struct LinkPreview_Previews: PreviewProvider {
  static let urls: [URL] = [
    URL(string: "https://www.theguardian.com/technology/2020/jan/21/amazon-boss-jeff-bezoss-phone-hacked-by-saudi-crown-prince")!,
  ]
  static var previews: some View {
    ForEach(Self.urls, id: \.absoluteString) { url in
      LinkPreview(link: url)
    }
  }
}

struct LinkBar: View {
  @ObservedObject var preferences: PreferencesData = .shared
  @Binding var scaleIcon: Bool

  let link: URL
  let iconOverride: Image?

  init(iconIsScaled: Binding<Bool>, icon: Image? = nil, link: URL) {
    _scaleIcon = iconIsScaled
    self.link = link
    iconOverride = icon
  }

  private var icon: Image {
    if iconOverride != nil { return iconOverride! }
    else {
      return preferences.browser.icon() != nil ?
        Image(nsImage: preferences.browser.icon()!) : Image(systemName: "safari")
    }
  }

  var body: some View {
    HStack(alignment: .center) {
      icon
        .resizable()
        .foregroundColor(.white)
        .frame(width: 24, height: 24)
        .padding(.leading, 4.0)
        .scaleEffect(self.scaleIcon ? 1.3 : 1.0)
      Rectangle()
        .fill(Color(.darkGray))
        .frame(width: 2, height: 24)
      Text(link.host ?? "")
        + Text(link.path)
        .foregroundColor(.secondary)
      Spacer()
    }
    .onTapGesture {
      openLink(self.link)
    }
    .padding(4)
    .frame(maxHeight: 32, alignment: .leading)
  }
}

private struct WebPreviewPopover: View {
  @Environment(\.hostingWindow) var hostingWindow
  @Binding var showingPreview: Bool
  let link: URL

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: {
          openLink(self.link)
          self.showingPreview = false
        }, label: {
          Text("Open")
        })
        SharingButton(items: [link], edge: .maxX)
        Spacer()
      }
      .padding(5)
      WebView(url: self.link)
    }
    .frame(width: (self.hostingWindow.frame?.width ?? 800) / 1.3333,
           height: (self.hostingWindow.screen??.frame.height ?? 1200) / 1.3333)
  }
}
