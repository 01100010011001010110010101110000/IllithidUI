//
// RootView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct RootView: View {
  var body: some View {
    InformationBarNavigationView()
      .toolbar { Spacer() }
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
