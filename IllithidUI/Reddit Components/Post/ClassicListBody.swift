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

// MARK: - ClassicListBody

struct ClassicListBody: View {
  // MARK: Internal

  @Namespace var ns
  let posts: [Post]
  let onLastPost: () -> Void

  var body: some View {
    ZStack {
      List {
        ForEach(posts) { post in
          PostClassicRowView(post: post)
            .onTapGesture {
              openModal(for: post)
            }
            .opacity(selection?.id == post.id ? 0.0 : 1.0)
            .onAppear {
              if post == posts.last {
                onLastPost()
              }
            }
        }
      }
      .disabled(selection != nil)
      .blur(radius: blur ? 25 : 0)
      .transition(.opacity)
      .zIndex(1)

      if let post = selection {
        RoundedRectangle(cornerRadius: 8)
          .onMouseGesture(mouseDown: {
            closeModal()
          }, mouseUp: {})
          .foregroundColor(.clear)
          .zIndex(2)

        PostModalView(post: post)
          .zIndex(3)
      }
    }
  }

  func openModal(for post: Post) {
    withAnimation(.modal) { selection = post }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  func closeModal() {
    withAnimation(.modal) { selection = nil }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = false }
    }
  }

  // MARK: Private

  @State private var blur: Bool = false
  @State private var selection: Post? = nil
}

private extension Animation {
  static let modal: Animation = .interactiveSpring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.25)
  static let blur: Animation = .linear(duration: 0.25)
}

// struct ClassicListBody_Previews: PreviewProvider {
//    static var previews: some View {
//      ClassicListBody(posts: .constant([]),
//                      postsData: .init(provider: /* TODO Fill in */),
//                      sorter: .init(sort: .best, topInterval: .day)
//      )
//    }
// }
