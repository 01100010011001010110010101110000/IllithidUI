//
// RootView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/10/20
//

import SwiftUI

import Illithid

enum NavigationLayout: String, CaseIterable, Identifiable {
  var id: String {
    rawValue
  }

  var toolbarIcon: some View {
    switch self {
    case .compact:
      return Image(systemName: "list.dash")
        .font(.caption)
    case .classic:
      return Image(systemName: "rectangle.split.3x1")
        .font(.caption)
    case .large:
      return Image(systemName: "squares.below.rectangle")
        .font(.caption)
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
  @State private var layout: NavigationLayout = NavigationLayoutKey.defaultValue

  var body: some View {
    InformationBarNavigationView()
      .environment(\.navigationLayout, layout)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Picker(selection: $layout, label: EmptyView(), content: {
            ForEach(NavigationLayout.allCases.reversed()) { layoutCase in
              layoutCase.toolbarIcon
                .foregroundColor(.white)
                .tag(layoutCase).padding(5)
            }
          })
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
