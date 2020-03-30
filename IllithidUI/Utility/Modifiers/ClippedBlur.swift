//
// ClippedBlur.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/29/20
//

import SwiftUI

struct ClippedBlurModifier<S: Shape>: ViewModifier {
  let shape: S

  @Binding var isBlurred: Bool

  init(blur: Binding<Bool>, shape: S) {
    _isBlurred = blur
    self.shape = shape
  }

  func body(content: Content) -> some View {
    content
      .blur(radius: isBlurred ? 100 : 0.0)
      .clipShape(shape)
  }
}
