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

import Cocoa
import Foundation
import SwiftUI

struct SharingButton: View {
  let items: [Any]
  let preferredEdge: NSRectEdge
  private let view = NSView()

  init(items: [Any], edge: NSRectEdge = .minY) {
    self.items = items
    preferredEdge = edge
  }

  var body: some View {
    Button(action: {
      let picker = NSSharingServicePicker(items: self.items)
      picker.show(relativeTo: .zero, of: self.view, preferredEdge: self.preferredEdge)
    }, label: {
      Image(systemName: "square.and.arrow.up")
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
