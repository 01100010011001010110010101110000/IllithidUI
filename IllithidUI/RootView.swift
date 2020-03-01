//
// RootView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct RootView: View {
  @ObservedObject var preferences: PreferencesData

  var body: some View {
    InformationBarNavigationView()
      .environmentObject(preferences)
  }
}

// #if DEBUG
// struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        RootView()
//    }
// }
// #endif 
