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

// MARK: - AsyncButton

struct AsyncButton<Label: View>: View {
  // MARK: Lifecycle

  init(role: ButtonRole? = nil, action: @escaping () async -> Void, label: @escaping () -> Label) {
    self.role = role
    self.action = action
    self.label = label
  }

  // MARK: Internal

  let role: ButtonRole?
  let action: () async -> Void
  @ViewBuilder let label: () -> Label

  var body: some View {
    Button(role: role, action: {
      Task {
        isDisabled = true
        await action()
        isDisabled = false
      }
    }, label: {
      label()
    }).disabled(isDisabled)
  }

  // MARK: Private

  @State private var isDisabled = false
}

extension AsyncButton where Label == Text {
  init(_ label: String, role: ButtonRole? = nil, action: @escaping () async -> Void) {
    self.init(role: role, action: action) { Text(NSLocalizedString(label, comment: "")) }
  }
}

extension AsyncButton where Label == Image {
  init(systemImageName: String, role: ButtonRole? = nil, action: @escaping () async -> Void) {
    self.init(role: role, action: action) { Image(systemName: systemImageName) }
  }
}
