//
// IllithidButton.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

struct IllithidButton: View {
  @State private var pressed: Bool = false

  let action: () -> Void
  let label: String

  var body: some View {
    Text(label)
      .padding([.leading, .trailing], 12)
      .padding([.top, .bottom], 2)
      .background(RoundedRectangle(cornerRadius: 2.0)
        .foregroundColor(self.pressed ? .accentColor : Color(.controlColor)))
      .onMouseGesture(mouseDown: {
        self.pressed = true
      }, mouseUp: {
        self.pressed = false
        self.action()
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
