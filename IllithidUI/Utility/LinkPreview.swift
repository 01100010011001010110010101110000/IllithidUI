//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import Foundation
import LinkPresentation
import os.log
import SwiftUI

import Alamofire
import SDWebImage
import SDWebImageSwiftUI
import SwiftSoup

// FIX: Wide aspect ratio resizing

struct LinkPreview: View {
  @State private var previewImageUrl: URL? = nil
  @State private var audioUrl: URL? = nil
  @State private var videoUrl: URL? = nil
  @State private var hover: Bool = false

  let link: URL

  private static let queue = DispatchQueue(label: "com.fayware.IllithidUI.LinkPreview", attributes: .concurrent)
  private let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.LinkPreview", category: .pointsOfInterest)

  var body: some View {
    Group {
      if videoUrl != nil {
        Player(url: videoUrl!)
          .frame(width: 512, height: 256)
      }
      else if audioUrl != nil {
        Player(url: audioUrl!)
          .frame(width: 512, height: 256)
      } else {
        VStack(spacing: 0.0) {
          if previewImageUrl != nil {
            VStack {
              WebImage(url: previewImageUrl!, context: [.imageTransformer: SDImageResizingTransformer(size: CGSize(width: 512, height: 336), scaleMode: .aspectFill)])
            }
          } else {
            EmptyView()
          }

          HStack(alignment: .center) {
            Image(nsImage: NSImage(named: .compass)!)
              .resizable()
              .foregroundColor(.white)
              .frame(width: 24, height: 24)
              .padding(.leading, 4.0)
              .scaleEffect(self.hover ? 1.3 : 1.0)
            Rectangle()
              .fill(Color(.darkGray))
              .frame(width: 2, height: 24)
            Text(link.absoluteString)
              .lineLimit(1)
              .truncationMode(.tail)
            Spacer()
          }
          .onHover(perform: { entered in
            withAnimation(.easeInOut(duration: 0.7)) {
              self.hover = entered
            }
          })
          .onTapGesture {
            NSWorkspace.shared.open(self.link)
          }
          .padding(4)
          .frame(maxHeight: 32, alignment: .leading)

        }
        .frame(width: 512)
        .background(Color(.controlBackgroundColor))
        .modifier(RoundedBorder(style: Color(.darkGray), cornerRadius: 8.0, width: 2.0))
        .onAppear {
          self.loadMetadata()
        }
      }
    }
  }

  private func loadMetadata() {
    AF.request(link).responseString(queue: Self.queue) { response in
      switch response.result {
      case let .success(html):
        // Fetch link's HTML document
        let documentResult = Result<Document, Error> {
          return try SwiftSoup.parse(html, self.link.absoluteString)
        }

        switch documentResult {
        case let .success(document):
          // Fetch page's audio media
          do {
            self.audioUrl = try document.select("audio")
              .first()
              .flatMap { try URL(string: $0.attr("src")) }
            if self.audioUrl == nil {
              let text = try document.html()
              let matches = self.detector.matches(in: text, options: [],
                                                  range: NSRange(location: 0, length: text.count))
              for match in matches {
                if let url = match.url, url.pathExtension == "m4a" {
                  self.audioUrl = url
                  return
                }
              }
            }
          } catch {
            print("Error parsing audio URL")
          }

          // Fetch page's preview image link from meta tags
          do {
            self.previewImageUrl = try document.select("meta")
              .first { try $0.attr("property") == "og:image" }
              .flatMap { try URL(string: $0.attr("content")) }
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
