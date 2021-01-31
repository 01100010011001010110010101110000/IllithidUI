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
  func deleteButton(alignment: Alignment = .topLeading, padLength: CGFloat = 5, onDelete: @escaping () -> Void) -> some View {
    modifier(DeleteButtonModifier(alignment: alignment, padLength: padLength, onDelete: onDelete))
  }
}

// MARK: - DeleteButton

struct DeleteButton: View {
  let onDelete: () -> Void

  var body: some View {
    Button(action: {
      onDelete()
    }, label: {
      Image(systemName: "xmark.circle.fill")
    })
      .keyboardShortcut(.delete, modifiers: .none)
  }
}

// MARK: - DeleteButtonModifier

struct DeleteButtonModifier: ViewModifier {
  // MARK: Internal

  let alignment: Alignment
  let padLength: CGFloat
  let onDelete: () -> Void

  func body(content: Content) -> some View {
    content
      .onHover { isHovered in
        withAnimation {
          self.isHovered = isHovered
        }
      }
      .overlay(DeleteButton(onDelete: onDelete)
        .padding(padLength)
        .opacity(isHovered ? 1 : 0), alignment: alignment)
  }

  // MARK: Private

  @State private var isHovered: Bool = false
}
