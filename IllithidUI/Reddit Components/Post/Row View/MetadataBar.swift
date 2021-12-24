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
  struct PostMetadataBar: View {
    // MARK: Internal

    let post: Post

    var body: some View {
      VStack(alignment: .leading, spacing: 5) {
        if let richText = post.authorFlairRichtext, !richText.isEmpty {
          FlairRichTextView(richText: richText,
                            backgroundColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor,
                            textColor: authorFlairTextColor)
        } else if let text = post.authorFlairText, !text.isEmpty {
          Text(text)
            .foregroundColor(authorFlairTextColor)
            .flairTag(rectangleColor: post.authorFlairBackgroundSwiftUiColor ?? .accentColor)
        }

        PostAttribution(post: post)

        HStack {
          (Text(Image(systemName: model.vote == .down ? "arrow.down" : "arrow.up"))
            + Text("\(post.ups.postAbbreviation())"))
            .foregroundColor(voteColor)

          (Text(Image(systemName: "text.bubble"))
            + Text("\(post.numComments.postAbbreviation())"))
            .foregroundColor(.blue)

          (Text(Image(systemName: "clock"))
            + Text("\(post.relativePostTime) ago"))
            .help(post.absolutePostTime)
        }
        .animation(.default, value: model.vote)
      }
      .font(.body)
    }

    // MARK: Private

    @EnvironmentObject private var model: CommonActionModel<Post>

    private let windowManager: WindowManager = .shared

    private var voteColor: Color? {
      switch model.vote {
      case .clear:
        return nil
      case .down:
        return .purple
      case .up:
        return .orange
      }
    }

    private var authorFlairTextColor: Color {
      post.authorFlairBackgroundSwiftUiColor == nil
        ? Color(.textColor)
        : post.authorFlairTextSwiftUiColor
    }
  }
}
