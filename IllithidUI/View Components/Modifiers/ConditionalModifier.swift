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

public extension View {
  /// If `condition` is true, return the `View` with the modifier applied, else return the same view
  /// - Parameters:
  ///   - condition: The condition to evaluate
  ///   - modifier: The `ViewModifier` to apply
  func conditionalModifier<M>(_ condition: Bool, _ modifier: M) -> some View where M: ViewModifier {
    Group {
      if condition {
        self.modifier(modifier)
      } else {
        self
      }
    }
  }

  /**
   If `condition` is true, apply the first modifier; else apply the second
   - Parameters:
      - condition: The condition to evaluate
      - trueModifier: The modifier to apply if `condition` is true
      - falseModifier: The modifier to apply if `condition` is false
   */
  func conditionalModifier<M1, M2>(_ condition: Bool, _ trueModifier: M1, _ falseModifier: M2) -> some View where M1: ViewModifier, M2: ViewModifier {
    Group {
      if condition {
        self.modifier(trueModifier)
      } else {
        self.modifier(falseModifier)
      }
    }
  }
}

/// Thin wrapper around the `onAppear` view extension to make it usable as a `ViewModifier`
/// - Parameter closure: The closure to execute when the view appears
struct OnAppearModifier: ViewModifier {
  let closure: () -> Void

  func body(content: Content) -> some View {
    content.onAppear { self.closure() }
  }
}
