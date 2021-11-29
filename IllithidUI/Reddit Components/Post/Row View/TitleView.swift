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

import Illithid

extension PostRowView {
  struct TitleView: View {
    // MARK: Internal

    let post: Post
    let alignment: HorizontalAlignment = .leading

    var body: some View {
      VStack(alignment: alignment) {
        HStack {
          if post.over18 {
            Text(verbatim: "NSFW")
              .flairTag(rectangleColor: .red)
          }
          if let richText = post.linkFlairRichtext, !richText.isEmpty {
            FlairRichTextView(richText: richText,
                              backgroundColor: post.linkFlairBackgroundSwiftUiColor ?? .accentColor,
                              textColor: flairTextColor)
          } else if let text = post.linkFlairText, !text.isEmpty {
            Text(verbatim: text)
              .foregroundColor(flairTextColor)
              .flairTag(rectangleColor: post.linkFlairBackgroundSwiftUiColor ?? .accentColor)
          }
        }

        Text(verbatim: post.title)
          .font(.title)
          .multilineTextAlignment(.leading)
      }
    }

    // MARK: Private

    private var flairTextColor: Color {
      post.linkFlairBackgroundSwiftUiColor == nil
        ? Color(.textColor)
        : post.authorFlairTextSwiftUiColor
    }
  }
}
