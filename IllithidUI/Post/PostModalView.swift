//
// PostModalView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/12/20
//

import SwiftUI

import Illithid

struct PostModalView: View {
  let post: Post

  var body: some View {
    PostContent(post: post)
      .shadow(radius: 10)
      .zIndex(3)
  }
}

// struct PostModalView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostModalView()
//    }
// }
