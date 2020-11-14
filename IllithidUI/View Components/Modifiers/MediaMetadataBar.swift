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

// MARK: - MediaMetadataBar

struct MediaMetadataBar: ViewModifier {
  @State private var displayed: Bool = false
  let metadata: MediaMetadataProvider

  func body(content: Content) -> some View {
    content
      .onHover { isHovering in
        withAnimation {
          displayed = isHovering
        }
      }
      .overlay(
        TextBar(metadata: metadata)
          .lineLimit(1)
          .padding()
          .background(Background())
          .opacity(displayed ? 1 : 0.0)
          .transition(.fade),
        alignment: .top
      )
  }

  private struct TextBar: View {
    let metadata: MediaMetadataProvider

    var body: some View {
      HStack {
        Text(metadata.hostDisplayName)
          .italic()
          .layoutPriority(2.0)
        if !metadata.mediaTitle.isEmpty {
          Text(metadata.mediaTitle)
            .help(metadata.mediaTitle)
            .layoutPriority(1.0)
        }
        Spacer()
        if let description = metadata.mediaDescription, !description.isEmpty {
          Label(description, systemImage: "text.bubble")
            .help(description)
          Spacer()
        }
        Label("\(metadata.views)", systemImage: "eye.fill")
      }
    }
  }

  private struct Background: View {
    var body: some View {
      Rectangle()
        .foregroundColor(.black)
        .opacity(0.8)
    }
  }
}

extension View {
  func mediaMetadataBar(metadata: MediaMetadataProvider) -> some View {
    modifier(MediaMetadataBar(metadata: metadata))
  }
}
