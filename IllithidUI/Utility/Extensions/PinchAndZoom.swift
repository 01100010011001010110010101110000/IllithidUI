//
// PinchAndZoom.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

extension View {
  func dragAndZoom() -> some View {
    modifier(PinchAndZoomModifier())
  }
}

private struct PinchAndZoomModifier: ViewModifier {
  @State private var currentScale: CGFloat = 1.0
  @State private var previousScale: CGFloat = 1.0

  @State private var currentPosition: CGSize = .zero
  @State private var previousPosition: CGSize = .zero
  @State private var resetVisibility: Double = .zero

  private func pinNewScale(newScale: CGFloat) -> CGFloat {
    if newScale < 5.0, newScale > 1.0 {
      return newScale
    } else {
      return currentScale
    }
  }

  private func resetPosition() {
    previousPosition = .zero
    currentPosition = .zero
  }

  private func resetZoom() {
    previousScale = 1.0
    currentScale = 1.0
  }

  func body(content: Content) -> some View {
    ZStack(alignment: .topLeading) {
      content
        .offset(currentPosition)
        .clipShape(Rectangle())
        .gesture(DragGesture()
          .onChanged({ value in
            if self.currentScale > 1.0 {
              self.currentPosition = CGSize(width: value.translation.width + self.previousPosition.width,
                                            height: value.translation.height + self.previousPosition.height)
            }
          })
          .onEnded({ _ in
            self.previousPosition = self.currentPosition
          }))

        .scaleEffect(currentScale)
        .clipShape(Rectangle())
        .gesture(MagnificationGesture()
          .onChanged({ value in
            self.currentScale = self.pinNewScale(newScale: value.magnitude * self.previousScale)
          })
          .onEnded({ _ in
            self.previousScale = self.currentScale
          }))

      HStack {
        Button(action: {
          self.resetZoom()
          // Altering scale alters the offset, so we reset it to ensure the whole view is visible
          self.resetPosition()
        }, label: {
          Image(systemName: "arrow.triangle.2.circlepath")
        })
      }
      .padding([.top, .leading], 4)
      .opacity(self.resetVisibility)
    }
    .onHover(perform: { isHovering in
      if isHovering {
        withAnimation(.easeIn(duration: 0.3)) {
          self.resetVisibility = 1.0
        }
      } else {
        withAnimation(.easeOut(duration: 0.3)) {
          self.resetVisibility = .zero
        }
      }
    })
  }
}
