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

struct WikiPagesView: View {
  @ObservedObject var wikiData: WikiData

  var body: some View {
    List {
      VStack {
        Text("Wiki Pages")
          .font(.largeTitle)
        Text("Below is a list of pages in this wiki which are visible to you")
      }
      Divider()
      ForEach(wikiData.pages, id: \.self) { link in
        Text(link.absoluteString)
      }
    }
    .onAppear {
      if wikiData.pages.isEmpty {
        wikiData.fetchWikiPages()
      }
    }
  }
}

// struct WikiPagesView_Previews: PreviewProvider {
//    static var previews: some View {
//        WikiPagesView()
//    }
// }
