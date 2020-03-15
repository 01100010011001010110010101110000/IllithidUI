//
// ResizingText.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/15/2020
//

import SwiftUI

/// Works around `List` row height being fixed by setting the child frame's`height` when its `size` adjusts
extension View {
  func heightResizable() -> some View {
    self.modifier(HeightResizingModifier())
  }
}

private struct HeightResizingModifier: ViewModifier {
  @State private var height: CGFloat = .zero

  func body(content: Content) -> some View {
    content
    .fixedSize(horizontal: false, vertical: true)
    .background(GeometryReader { proxy -> AnyView in
      DispatchQueue.main.async {
        self.height = proxy.size.height
      }
      return Rectangle()
        .fill(Color.clear)
        .eraseToAnyView()
    })
    .frame(height: height)
  }
}
