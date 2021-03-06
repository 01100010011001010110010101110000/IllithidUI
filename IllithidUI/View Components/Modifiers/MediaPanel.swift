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

import SwiftUI

// MARK: - MediaPanelOverlay

struct MediaPanelOverlay: ViewModifier {
  // MARK: Lifecycle

  init(size: NSSize, cornerRadius: CGFloat = 8, resizable: Bool = true) {
    self.size = size
    self.cornerRadius = cornerRadius
    self.resizable = resizable
  }

  // MARK: Internal

  struct PanelCloseButton: View {
    @Environment(\.hostingWindow) var window

    var body: some View {
      Button(action: {
        if let windowNumber = window.windowNumber, let resolvedWindow = NSApp.window(withWindowNumber: windowNumber) {
          resolvedWindow.close()
        }
      }, label: {
        Image(systemName: "xmark.circle.fill")
      })
        .keyboardShortcut(.cancelAction)
    }
  }

  let size: NSSize
  let cornerRadius: CGFloat
  let resizable: Bool

  func body(content: Content) -> some View {
    let size = initialSize
    return Group {
      if resizable {
        content
          .aspectRatio(contentMode: .fit)
          .frame(minWidth: size.width, minHeight: size.height)
      } else {
        content
          .frame(width: size.width, height: size.height)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .overlay(PanelCloseButton().padding(10), alignment: .topLeading)
  }

  // MARK: Private

  @Environment(\.hostingWindow) private var window

  private var initialSize: CGSize {
    guard let screenSize = self.screenSize else { return size }
    if size.width > (screenSize.width - 100) || size.height > (screenSize.height - 100) {
      let ratio = 1.5 * max(size.width / screenSize.width, size.height / screenSize.height)
      return .init(width: size.width / ratio, height: size.height / ratio)
    } else {
      return size
    }
  }

  private var screenSize: NSSize? {
    // TODO: Multiscreen support by fetching the screen the window/view is actually on
    NSScreen.main?.frame.size
  }

  private var resolvedWindow: NSWindow? {
    guard let windowNumber = window.windowNumber else { return nil }
    return NSApp.window(withWindowNumber: windowNumber)
  }
}

extension View {
  func mediaPanelOverlay(size: NSSize, cornerRadius: CGFloat = 8, resizable: Bool = true) -> some View {
    modifier(
      MediaPanelOverlay(size: size,
                        cornerRadius: cornerRadius,
                        resizable: resizable)
    )
  }
}

// MARK: - MediaPanel_Previews

struct MediaPanel_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle()
      .frame(width: 100, height: 100)
      .modifier(MediaPanelOverlay(size: NSSize(width: 100, height: 200)))
  }
}
