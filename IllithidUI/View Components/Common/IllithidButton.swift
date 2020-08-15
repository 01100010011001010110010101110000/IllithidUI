//
// IllithidButton.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

struct IllithidButton: View {
  @State private var pressed: Bool = false

  let mouseDown: () -> Void
  let mouseUp: () -> Void
  let label: AnyView

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
}

extension View {
  func onMouseGesture(mouseDown: @escaping () -> Void, mouseUp: @escaping () -> Void) -> some View {
    overlay(MouseView(onMouseDown: mouseDown, onMouseUp: mouseUp))
  }
}

private struct MouseView: NSViewRepresentable {
  let onMouseDown: () -> Void
  let onMouseUp: () -> Void

  class NSMouseView: NSView {
    let onMouseDown: () -> Void
    let onMouseUp: () -> Void

    init(onMouseDown: @escaping () -> Void, onMouseUp: @escaping () -> Void) {
      self.onMouseDown = onMouseDown
      self.onMouseUp = onMouseUp

      super.init(frame: .zero)
    }

    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with _: NSEvent) {
      onMouseDown()
    }

    override func mouseUp(with _: NSEvent) {
      onMouseUp()
    }
  }

  func makeNSView(context _: NSViewRepresentableContext<MouseView>) -> NSMouseView {
    NSMouseView(onMouseDown: onMouseDown, onMouseUp: onMouseUp)
  }

  func updateNSView(_: NSMouseView, context _: NSViewRepresentableContext<MouseView>) {}
}
