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

struct RedditLinkView: View {
  @State private var hover: Bool = false
  let link: URL

  private let icon = Image(named: .redditSquare)
  private let windowManager: WindowManager = .shared

  var body: some View {
    VStack {
      LinkBar(iconIsScaled: $hover, icon: icon, link: link)
        .frame(width: 512)
        .background(Color(.controlBackgroundColor))
        .roundedBorder(style: Color(.darkGray), width: 2.0)
        .onHover { entered in
          withAnimation(.easeInOut(duration: 0.7)) {
            hover = entered
          }
        }
    }
  }

  private func openRedditLink(link: URL) {
    windowManager.openRedditLink(link: link)
  }
}

// struct RedditLinkView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedditLinkView()
//    }
// }
