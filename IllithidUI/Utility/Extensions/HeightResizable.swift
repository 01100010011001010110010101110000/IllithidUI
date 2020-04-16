//
// HeightResizable.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/1/20
//

import Combine
import SwiftUI

/// Works around `List` row height being fixed by setting the child frame's`height` when its `size` adjusts
extension View {
  func heightResizable(maxHeight: CGFloat = .infinity) -> some View {
    modifier(HeightResizingModifier(maxHeight: maxHeight))
  }
}

private struct HeightResizingModifier: ViewModifier {
  @State private var frame: CGRect = .zero

  let maxHeight: CGFloat

  func body(content: Content) -> some View {
    content
      .frame(maxHeight: maxHeight)
      .fixedSize(horizontal: false, vertical: true)
      .background(FramePreferenceViewSetter())
      .frame(height: frame.height)
      .onPreferenceChange(FramePreferenceKey.self, perform: { newFrame in
        self.frame = newFrame
      })
  }
}

private struct FramePreferenceViewSetter: View {
  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.clear)
        .preference(key: FramePreferenceKey.self,
                    value: geometry.frame(in: .local))
    }
  }
}

private struct FramePreferenceKey: PreferenceKey {
  typealias Value = CGRect

  static var defaultValue: CGRect = .zero

  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}
