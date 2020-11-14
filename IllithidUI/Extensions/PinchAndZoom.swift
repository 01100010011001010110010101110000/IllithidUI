// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI

extension View {
  func dragAndZoom() -> some View {
    modifier(PinchAndZoomModifier())
  }
}

// MARK: - PinchAndZoomModifier

private struct PinchAndZoomModifier: ViewModifier {
  // MARK: Internal

  func body(content: Content) -> some View {
    ZStack(alignment: .bottomTrailing) {
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

  // MARK: Private

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
}
