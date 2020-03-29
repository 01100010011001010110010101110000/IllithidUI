//
// PinchAndZoom.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/29/20
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
        DragResetButton {
          self.resetPosition()
        }
        ZoomResetButton()
          .onTapGesture {
            self.resetZoom()
            // Altering scale alters the offset, so we reset it to ensure the whole view is visible
            self.resetPosition()
          }
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

private struct ZoomResetButton: View {
  var body: some View {
    Image(named: .search)
      .resizable()
      .frame(width: 24, height: 24)
      .padding(4)
      .background(RoundedRectangle(cornerRadius: 4.0, style: .continuous)
        .fill(Color(.darkGray))
      )
  }
}

private struct DragResetButton: View {
  @State private var scale: CGFloat = 1.0

  let action: () -> Void

  var body: some View {
    Image(named: .arrowDownRightUpLeft)
      .resizable()
      .frame(width: 24, height: 24)
      .scaleEffect(scale)
      .animation(.linear(duration: 0.3))
      .padding(4)
      .background(RoundedRectangle(cornerRadius: 4.0, style: .continuous)
        .fill(Color(.darkGray))
      )
      .onTapGesture {
        self.scale = 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.scale = 1.0
        }
        self.action()
      }
  }
}
