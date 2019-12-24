//
// LinkPreview.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Foundation
import LinkPresentation
import SwiftUI

struct LinkPreview: NSViewRepresentable {
  @State private var reload = false

  let link: URL

  func makeNSView(context _: NSViewRepresentableContext<LinkPreview>) -> LPLinkView {
    let view = LPLinkView(url: link)

    let metadataProvider = LPMetadataProvider()
    metadataProvider.startFetchingMetadata(for: link) { wrappedMetadata, wrappedError in
      if let metadata = wrappedMetadata {
        view.metadata = metadata
        DispatchQueue.main.async {
          view.setFrameSize(view.fittingSize)
          self.reload.toggle()
        }
      } else if let error = wrappedError {
        let metadata = LPLinkMetadata()
        metadata.title = "Failed to fetch metadtaa"
        view.metadata = metadata
        DispatchQueue.main.async {
          view.setFrameSize(view.fittingSize)
          self.reload.toggle()
        }
      }
    }
    return view
  }

  func updateNSView(_: LPLinkView, context _: NSViewRepresentableContext<LinkPreview>) {
    // Create a new instance on each update
  }
}
