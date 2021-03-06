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

import Foundation
import SwiftUI

extension View {
  func loadingScreen(isLoading: Bool, offset: (x: CGFloat, y: CGFloat) = (x: 0, y: 0), dimBackground: Bool = false) -> some View {
    overlay(
      ZStack {
        if isLoading {
          if dimBackground {
            Rectangle()
              .foregroundColor(.black)
              .opacity(0.8)
          }
          ProgressView()
            .offset(x: offset.x, y: offset.y)
        }
      }
    )
  }

  func loadingScreen(isLoading: Bool, title: String, offset: (x: CGFloat, y: CGFloat) = (x: 0, y: 0), dimBackground: Bool = false) -> some View {
    overlay(
      ZStack {
        if isLoading {
          if dimBackground {
            Rectangle()
              .foregroundColor(.black)
              .opacity(0.8)
          }
          ProgressView(NSLocalizedString(title, comment: ""))
            .offset(x: offset.x, y: offset.y)
        }
      }
    )
  }

  func loadingScreen<Content: View>(isLoading: Bool, offset: (x: CGFloat, y: CGFloat) = (x: 0, y: 0), dimBackground: Bool = false, @ViewBuilder _ label: () -> Content) -> some View {
    overlay(
      ZStack {
        if isLoading {
          if dimBackground {
            Rectangle()
              .foregroundColor(.black)
              .opacity(0.8)
          }
          ProgressView(label: label)
            .offset(x: offset.x, y: offset.y)
        }
      }
    )
  }
}
