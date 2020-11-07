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
    _AttributedText(attributed: attributed, height: $height)
      .frame(minWidth: 20, minHeight: 20, idealHeight: max(20, height))
      .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: Private

  @State private var height: CGFloat = .zero
  private let attributed: NSAttributedString
}

// MARK: - AttributedTextView

private final class AttributedTextView: NSTextView {
  // MARK: Lifecycle

  init(height: Binding<CGFloat>) {
    _height = height
    let view = NSTextView(frame: .zero)
    super.init(frame: view.frame, textContainer: view.textContainer)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let container = NSTextContainer()

  // MARK: Private

  @Binding private var height: CGFloat
}

// MARK: - _AttributedText

private struct _AttributedText: NSViewRepresentable {
  // MARK: Lifecycle

  init(attributed: NSAttributedString, height: Binding<CGFloat>) {
    self.attributed = NSMutableAttributedString(attributedString: attributed)
    self.attributed.addAttributes([.font: NSFont.systemFont(ofSize: 0)], range: NSRange(location: 0, length: self.attributed.length))

    _height = height
  }

  // MARK: Internal

  typealias NSViewType = AttributedTextView

  final class Coordinator: NSObject, NSTextViewDelegate {
    // MARK: Lifecycle

    init(height: Binding<CGFloat>) {
      _height = height
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

    // MARK: Private

    private var tokens: [AnyCancellable] = []
  }

  let attributed: NSMutableAttributedString
  @Binding var height: CGFloat

  func makeNSView(context: Context) -> AttributedTextView {
    let view = AttributedTextView(height: $height)

    view.autoresizingMask = [.height, .width]
    view.isEditable = false
    view.drawsBackground = false
    view.backgroundColor = NSColor.clear
    view.postsFrameChangedNotifications = true

    view.textStorage?.setAttributedString(attributed)
    view.textColor = NSColor.textColor

    view.delegate = context.coordinator
    context.coordinator.listenToChanges(for: view)
    DispatchQueue.main.async {
      self.height = view.textHeight
    }

    return view
  }

  func updateNSView(_: AttributedTextView, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(height: $height)
  }
}

private extension NSTextView {
  var textHeight: CGFloat {
    guard layoutManager != nil, textContainer != nil else { return 0 }
    return layoutManager!.usedRect(for: textContainer!).height
  }
}
