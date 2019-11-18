//
//  LinkPreview.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
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
        view.setFrameSize(view.fittingSize)
        self.reload.toggle()
      }
    }
    return view
  }

  func updateNSView(_: LPLinkView, context _: NSViewRepresentableContext<LinkPreview>) {
    // Create a new instance on each update
  }
}
