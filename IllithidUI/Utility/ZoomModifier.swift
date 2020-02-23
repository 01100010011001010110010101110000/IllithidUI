//
// ZoomModifier.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 02/23/2020
//

import SwiftUI

extension View {
  func zoomable() -> some View {
    modifier(ZoomModifier())
  }
}

struct ZoomModifier: ViewModifier {
  @State private var currentScale: CGFloat = 1.0
  @State private var previousScale: CGFloat = 1.0

  func body(content: Content) -> some View {
    content
      .scaleEffect(currentScale)
      .clipShape(Rectangle())
      .gesture(MagnificationGesture()
        .onChanged({ value in
          self.currentScale = value.magnitude * self.previousScale
        })
        .onEnded({ value in
          self.currentScale = value.magnitude * self.previousScale
          self.previousScale = value.magnitude * self.previousScale
        }))
  }
}
