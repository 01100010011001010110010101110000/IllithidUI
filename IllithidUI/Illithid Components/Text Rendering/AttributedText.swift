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

import AppKit
import Combine
import Foundation
import SwiftUI
import WebKit

// MARK: - AttributedText

struct AttributedText: View {
  // MARK: Lifecycle

  init(attributed: NSAttributedString) {
    self.attributed = attributed
  }

  // MARK: Internal

  var body: some View {
    AttributedTextRepresentable(attributed: attributed, height: $height)
      .frame(minWidth: 1, minHeight: 1, idealHeight: max(1, height))
      .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: Private

  // MARK: - AttributedTextRepresentable

  private struct AttributedTextRepresentable: NSViewRepresentable {
    // MARK: Lifecycle

    init(attributed: NSAttributedString, height: Binding<CGFloat>) {
      self.attributed = NSMutableAttributedString(attributedString: attributed)
      self.attributed.addAttributes([.font: NSFont.systemFont(ofSize: 0)], range: NSRange(location: 0, length: self.attributed.length))
      self.attributed.addAttributes([.foregroundColor: NSColor.textColor], range: NSRange(location: 0, length: self.attributed.length))

      _height = height
    }

    // MARK: Internal

    typealias NSViewType = NSTextView

    final class Coordinator: NSObject, NSTextViewDelegate {
      // MARK: Lifecycle

      init(height: Binding<CGFloat>) {
        _height = height
      }

      deinit {
        cancel()
      }

      // MARK: Internal

      @Binding var height: CGFloat

      func listenToChanges(for view: NSTextView) {
        tokens.append(NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: view)
          .sink { notification in
            DispatchQueue.main.async { [weak self] in
              guard let self = self, let view = notification.object as? NSTextView else { return }
              self.height = view.textHeight
            }
          })
      }

      func cancel() {
        while !tokens.isEmpty {
          tokens.popLast()?.cancel()
        }
      }

      // MARK: Private

      private var tokens: [AnyCancellable] = []
    }

    let attributed: NSMutableAttributedString
    @Binding var height: CGFloat

    static func dismantleNSView(_: NSTextView, coordinator: Coordinator) {
      coordinator.cancel()
    }

    func makeNSView(context: Context) -> NSTextView {
      let view = NSTextView()

      view.autoresizingMask = [.height, .width]
      view.isEditable = false
      view.drawsBackground = false
      view.postsFrameChangedNotifications = true

      view.delegate = context.coordinator
      context.coordinator.listenToChanges(for: view)

      view.textStorage?.setAttributedString(attributed)

      DispatchQueue.main.async {
        self.height = view.textHeight
      }

      return view
    }

    func updateNSView(_: NSTextView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
      Coordinator(height: $height)
    }
  }

  @State private var height: CGFloat = .zero
  private let attributed: NSAttributedString
}

private extension NSTextView {
  var textHeight: CGFloat {
    guard layoutManager != nil, textContainer != nil else { return 0 }
    return layoutManager!.usedRect(for: textContainer!).height
  }
}
