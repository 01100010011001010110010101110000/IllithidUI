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

enum NavigationLayout: String, CaseIterable, Identifiable, Codable {
  var id: String {
    rawValue
  }

  var toolbarIcon: some View {
    Image(systemName: iconName)
      .font(.caption)
  }

  var iconName: String {
    switch self {
    case .compact:
      return "list.dash"
    case .classic:
      return "rectangle.split.3x1"
    case .large:
      return "squares.below.rectangle"
    }
  }

  case compact
  case classic
  case large
}

struct NavigationLayoutKey: EnvironmentKey {
  static var defaultValue: NavigationLayout = .large
}

extension EnvironmentValues {
  var navigationLayout: NavigationLayout {
    get {
      self[NavigationLayoutKey.self]
    }
    set {
      self[NavigationLayoutKey.self] = newValue
    }
  }
}

struct RootView: View {
  @AppStorage("navigationLayout") var layout: NavigationLayout = NavigationLayoutKey.defaultValue

  var body: some View {
    InformationBarNavigationView()
      .environment(\.navigationLayout, layout)
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Button(action: {
            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
          }, label: {
            Image(systemName: "sidebar.left")
          })
        }
        ToolbarItem(placement: .principal) {
          Picker(selection: $layout, label: EmptyView()) {
            ForEach(NavigationLayout.allCases.reversed()) { layoutCase in
              layoutCase.toolbarIcon
                .foregroundColor(.white)
                .tag(layoutCase).padding(5)
            }
          }
          .help("Different layout styles for the main navigation page")
          .pickerStyle(SegmentedPickerStyle())
        }
      }
      .navigationTitle("Illithid")
  }
}

// #if DEBUG
// struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        RootView()
//    }
// }
// #endif 
