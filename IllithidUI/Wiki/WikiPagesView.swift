//
// WikiPagesView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/18/20
//

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
      if self.wikiData.pages.isEmpty {
        self.wikiData.fetchWikiPages()
      }
    }
  }
}

// struct WikiPagesView_Previews: PreviewProvider {
//    static var previews: some View {
//        WikiPagesView()
//    }
// }
