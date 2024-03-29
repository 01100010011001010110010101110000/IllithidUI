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

// MARK: - RootView

struct RootView: View {
  // MARK: Internal

  @AppStorage("postStyle") var postStyle: PostStyle = PostStyleKey.defaultValue

  var body: some View {
    Group {
      switch preferences.navigationStyle {
      case .multiColumn:
        PostGridView()
      case .linear:
        TriplePaneLayoutView()
      }
    }
    .postStyle(postStyle)
    .navigationStyle(preferences.navigationStyle)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button(action: {
          NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        }, label: {
          Image(systemName: "sidebar.left")
        })
          .help("Hide or show the navigator")
      }
      ToolbarItem(placement: .principal) {
        Picker(selection: $postStyle, label: EmptyView()) {
          ForEach(PostStyle.allCases.reversed()) { layoutCase in
            layoutCase.toolbarIcon
              .foregroundColor(.white)
              .tag(layoutCase).padding(5)
          }
        }
        .help("Different layout styles for the main navigation page")
        .pickerStyle(.segmented)
      }
    }
    .navigationTitle("Illithid")
  }

  // MARK: Private

  @ObservedObject private var preferences: PreferencesData = .shared
}

// #if DEBUG
// struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        RootView()
//    }
// }
// #endif
