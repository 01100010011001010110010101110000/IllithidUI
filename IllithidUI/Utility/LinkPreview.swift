//
// LinkPreview.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Foundation
import LinkPresentation
import SwiftUI

// FIX: Wide aspect ratio resizing

struct LinkPreview: View {
  @State private var previewImage: NSImage? = nil
  @State private var previewIcon: NSImage? = nil
  let link: URL

  var body: some View {
    VStack {
      if previewImage != nil {
        Image(nsImage: previewImage!)
          .resizable()
          .scaledToFit()
      } else {
        Rectangle()
          .opacity(0.0)
      }
      Divider()
      HStack {
        if self.previewIcon != nil {
          Image(nsImage: previewIcon!)
            .resizable()
            .frame(width: 32, height: 32)
            .scaledToFill()
        } else {
          Image(nsImage: NSImage(imageLiteralResourceName: "NSAdvanced"))
            .resizable()
            .frame(width: 32, height: 32)
            .scaledToFill()
        }
        Divider()
          .frame(height: 32)
        Text(link.absoluteString)
          .lineLimit(1)
          .truncationMode(.tail)
        Spacer()
      }
      .padding([.bottom, .leading, .trailing], 4)
      .frame(alignment: .leading)
    }
    .frame(maxWidth: 512, minHeight: 384, maxHeight: 384)
    .border(Color.gray, width: 2)
    .onAppear {
      self.loadMetadata(link: self.link)
    }
  }

  private func loadMetadata(link _: URL) {
    let provider = LPMetadataProvider()
    provider.startFetchingMetadata(for: link) { metadata, error in
      if let metadata = metadata {
        metadata.imageProvider?.loadDataRepresentation(forTypeIdentifier: String(kUTTypeImage), completionHandler: { data, error in
          guard error == nil else {
            print("Error fetching preview image: \(error!)")
            return
          }
          guard let data = data else {
            print("No image data")
            return
          }
          self.previewImage = NSImage(data: data)
        })
        metadata.iconProvider?.loadDataRepresentation(forTypeIdentifier: String(kUTTypeImage), completionHandler: { data, error in
          guard error == nil else {
            print("Error fetching preview icon: \(error!)")
            return
          }
          guard let data = data else {
            print("No icon data")
            return
          }
          self.previewIcon = NSImage(data: data)
        })
      } else if let error = error {
        print("Error fetching metadata: \(error)")
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
