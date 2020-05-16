//
// SharingButton.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/15/20
//

import Cocoa
import Foundation
import SwiftUI

struct SharingButton: View {
  let items: [Any]
  private let view = NSView()

  var body: some View {
    Button(action: {
      let picker = NSSharingServicePicker(items: self.items)
      picker.show(relativeTo: .zero, of: self.view, preferredEdge: .minY)
    }, label: {
      Image(named: NSImage.shareTemplateName)
    })
      .overlay(SharingOverlay(view: view))
  }
}

private struct SharingOverlay: NSViewRepresentable {
  typealias NSViewType = NSView
  let view: NSView

  init(view: NSView) {
    self.view = view
  }

  func makeNSView(context _: Context) -> NSView {
    view
  }

  func updateNSView(_: NSView, context _: Context) {}
}

struct SharingButton_Preview: PreviewProvider {
  static var previews: some View {
    SharingButton(items: [])
  }
}
