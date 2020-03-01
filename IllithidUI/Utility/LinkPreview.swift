//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Combine
import Foundation
import LinkPresentation
import os.log
import SwiftUI

import Alamofire
import SDWebImage
import SDWebImageSwiftUI
import SwiftSoup

struct LinkPreview: View {
  @State private var hover: Bool = false
  @ObservedObject var previewData: LinkPreviewData
  
  private let browserImage: NSImage

  init(link: URL) {
    self.previewData = .init(link: link)
    
    switch DefaultBrowser.atStartup {
    case .safari:
      browserImage = NSImage(named: .compass)!
    case .chrome:
      browserImage = NSImage(named: .chrome)!
    case .firefox:
      browserImage = NSImage(named: .firefox)!
    default:
      browserImage = NSImage(named: .compass)!
    }
  }

  var body: some View {
    VStack(spacing: 0.0) {
      previewData.previewImageUrl.map { url in
        WebImage(url: url, context: [.imageTransformer:
          SDImageResizingTransformer(size: CGSize(width: 512, height: 336), scaleMode: .aspectFill)
        ])
      }

      HStack(alignment: .center) {
        Image(nsImage: browserImage)
          .resizable()
          .foregroundColor(.white)
          .frame(width: 24, height: 24)
          .padding(.leading, 4.0)
          .scaleEffect(self.hover ? 1.3 : 1.0)
        Rectangle()
          .fill(Color(.darkGray))
          .frame(width: 2, height: 24)
        Text(previewData.link.host ?? "")
          + Text(previewData.link.path)
            .foregroundColor(.secondary)
        Spacer()
      }
      .onHover(perform: { entered in
        withAnimation(.easeInOut(duration: 0.7)) {
          self.hover = entered
        }
      })
      .onTapGesture {
        NSWorkspace.shared.open(self.previewData.link)
      }
      .padding(4)
      .frame(maxHeight: 32, alignment: .leading)

    }
    .frame(width: 512)
    .background(Color(.controlBackgroundColor))
    .modifier(RoundedBorder(style: Color(.darkGray), cornerRadius: 8.0, width: 2.0))
    .onAppear {
      self.previewData.loadMetadata()
    }
    .onDisappear {
      self.previewData.cancel()
    }
  }
}

final class LinkPreviewData: ObservableObject {
  @Published var previewImageUrl: URL?
  @Published var previewImage: NSImage?

  let link: URL
  private var request: DataRequest?

  init(link: URL) {
    self.link = link
  }

  private static let queue = DispatchQueue(label: "com.fayware.IllithidUI.LinkPreview")
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.LinkPreview", category: .pointsOfInterest)

  func loadMetadata() {
    self.request = AF.request(link).responseString(queue: Self.queue) { response in
      switch response.result {
      case let .success(html):
        // Fetch link's HTML document
        let documentResult = Result<Document, Error> {
          return try SwiftSoup.parse(html, self.link.absoluteString)
        }

        switch documentResult {
        case let .success(document):
          // Fetch page's preview image link from meta tags
          do {
            let url = try document.select("meta")
              .first { try $0.attr("property") == "og:image" }
              .flatMap { try URL(string: $0.attr("content")) }
            DispatchQueue.main.async {
              self.previewImageUrl = url
            }
          } catch {
            print("Error parsing link preview image URL: \(error)")
          }

        case let .failure(error):
          print("Error parsing link DOM: \(error)")
        }
      case let .failure(error):
        print("Error fetching HTML: \(error)")
      }
    }
  }

  func cancel() {
    self.request?.cancel()
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
