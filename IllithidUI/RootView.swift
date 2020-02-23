//
// RootView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct RootView: View {
  var subredditWindowManager: WindowManager = WindowManager<PostListView<Subreddit>>()

  var body: some View {
    InformationBarNavigationView()
      .environmentObject(subredditWindowManager)
  }
}

// #if DEBUG
// struct RootView_Previews: PreviewProvider {
//    static var previews: some View {
//        RootView()
//    }
// }
// #endif 
