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

extension View {
  func roundedBorder<Style: ShapeStyle>(style: Style, cornerRadius: CGFloat = 8, width: CGFloat = 1) -> some View {
    self.modifier(RoundedBorder(style: style, cornerRadius: cornerRadius, width: width))
  }
}