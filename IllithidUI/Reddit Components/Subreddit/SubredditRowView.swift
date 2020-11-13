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
import SDWebImageSwiftUI

struct SubredditRowView: View {
  let subreddit: Subreddit

  var body: some View {
    HStack {
      if let headerImageUrl = subreddit.headerImg {
        WebImage(url: headerImageUrl)
          .resizable()
          .scaledToFit()
          .frame(width: 96, height: 96)
      } else {
        // TODO: Replace with proper placeholder image
        Image(nsImage: NSImage(imageLiteralResourceName: "NSUser"))
          .scaledToFit()
          .frame(width: 96, height: 96)
      }
      Text(subreddit.displayName)
        .font(.headline)
        .padding(.leading)
        .lineLimit(1)
        .fixedSize()
    }
    .help(subreddit.publicDescription)
  }
}

// #if DEBUG
// struct SubredditRowView_Previews : PreviewProvider {
//    static var previews: some View {
//        SubredditRowView()
//    }
// }
// #endif
