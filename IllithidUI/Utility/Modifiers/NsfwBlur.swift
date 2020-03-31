//
// NsfwBlur.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/29/20
//

import SwiftUI

struct NsfwBlurModifier: ViewModifier {
  @ObservedObject var preferences: PreferencesData = .shared
  @State private var blur: Bool = false

  func body(content: Content) -> some View {
    content
      .modifier(ClippedBlurModifier(blur: $blur, shape: Rectangle()))
      .onTapGesture {
        withAnimation {
          self.blur = false
        }
      }
      .onReceive(preferences.$blurNsfw) { shouldBlur in
        withAnimation {
          self.blur = shouldBlur
        }
      }
  }
}

struct ClippedBlurModifier<S: Shape>: ViewModifier {
  @Binding var isBlurred: Bool

  let shape: S
  let radius: CGFloat
  let opaque: Bool

  init(blur: Binding<Bool>, shape: S, radius: CGFloat = 100, opaque: Bool = false) {
    _isBlurred = blur
    self.shape = shape
    self.radius = radius
    self.opaque = opaque
  }

  func body(content: Content) -> some View {
    content
      .blur(radius: isBlurred ? radius : 0.0, opaque: opaque)
      .clipShape(shape)
  }
}
