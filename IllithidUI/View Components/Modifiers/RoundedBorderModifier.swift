//
// RoundedBorderModifier.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

struct RoundedBorder<Style: ShapeStyle>: ViewModifier {
  let style: Style
  let cornerRadius: CGFloat
  let width: CGFloat

  func body(content: Content) -> some View {
    content
      .overlay(RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(style, lineWidth: width))
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}
