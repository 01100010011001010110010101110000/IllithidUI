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

// MARK: - IllithidButton

struct IllithidButton: View {
  // MARK: Lifecycle

  init<S: StringProtocol>(label: S,
                          mouseDown: @escaping () -> Void = {},
                          mouseUp: @escaping () -> Void) {
    self.mouseUp = mouseUp
    self.mouseDown = mouseDown
    self.label = Text(label)
      .eraseToAnyView()
  }

  init<V: View>(@ViewBuilder label: () -> V,
                mouseDown: @escaping () -> Void = {},
                mouseUp: @escaping () -> Void) {
    self.mouseUp = mouseUp
    self.mouseDown = mouseDown
    self.label = label()
      .eraseToAnyView()
  }

  // MARK: Internal

  let mouseDown: () -> Void
  let mouseUp: () -> Void
  let label: AnyView

  var body: some View {
    label
      .padding([.leading, .trailing], 12)
      .padding([.top, .bottom], 2)
      .background(RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(pressed ? .accentColor : Color(.controlColor)))
      .onMouseGesture(mouseDown: {
        pressed = true
        mouseDown()
      }, mouseUp: {
        pressed = false
        mouseUp()
      })
  }

  // MARK: Private

  @State private var pressed: Bool = false
}

extension View {
  func onMouseGesture(mouseDown: @escaping () -> Void, mouseUp: @escaping () -> Void) -> some View {
    overlay(MouseView(onMouseDown: mouseDown, onMouseUp: mouseUp))
  }
}

// MARK: - MouseView

private struct MouseView: NSViewRepresentable {
  class NSMouseView: NSView {
    // MARK: Lifecycle

    init(onMouseDown: @escaping () -> Void, onMouseUp: @escaping () -> Void) {
      self.onMouseDown = onMouseDown
      self.onMouseUp = onMouseUp

      super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let onMouseDown: () -> Void
    let onMouseUp: () -> Void

    override func mouseDown(with _: NSEvent) {
      onMouseDown()
    }

    override func mouseUp(with _: NSEvent) {
      onMouseUp()
    }
  }

  let onMouseDown: () -> Void
  let onMouseUp: () -> Void

  func makeNSView(context _: NSViewRepresentableContext<MouseView>) -> NSMouseView {
    NSMouseView(onMouseDown: onMouseDown, onMouseUp: onMouseUp)
  }

  func updateNSView(_: NSMouseView, context _: NSViewRepresentableContext<MouseView>) {}
}
