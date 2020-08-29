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
