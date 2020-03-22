//
// DraggableModifier.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

extension View {
  func draggable() -> some View {
    modifier(DraggableModifier())
  }
}

struct DraggableModifier: ViewModifier {
  @State private var currentPosition: CGSize = .zero
  @State private var newPosition: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .offset(currentPosition)
      .clipShape(Rectangle())
      .gesture(DragGesture()
        .onChanged({ value in
          self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width,
                                        height: value.translation.height + self.newPosition.height)
        })
        .onEnded({ value in
          self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width,
                                        height: value.translation.height + self.newPosition.height)
          print(self.newPosition.width)
          self.newPosition = self.currentPosition
        }))
  }
}
