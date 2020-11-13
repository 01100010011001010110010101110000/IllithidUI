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

import Combine
import SwiftUI

/// Works around `List` row height being fixed by setting the child frame's`height` when its `size` adjusts
extension View {
  func heightResizable(maxHeight: CGFloat = .infinity) -> some View {
    modifier(HeightResizingModifier(maxHeight: maxHeight))
  }
}

// MARK: - HeightResizingModifier

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

// MARK: - FramePreferenceViewSetter

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

// MARK: - FramePreferenceKey

private struct FramePreferenceKey: PreferenceKey {
  typealias Value = CGRect

  static var defaultValue: CGRect = .zero

  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}
