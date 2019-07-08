//
//  SearchView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 7/8/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct SearchView: View {
  @State var query: String = ""
  @ObjectBinding var queryResults: SearchData = .init()

  let reddit: RedditClientBroker

  var body: some View {
    VStack {
      TextField($query, placeholder: Text("Search Reddit")).textFieldStyle(.roundedBorder)
    }.frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
  }
}

// #if DEBUG
// struct SearchView_Previews : PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
// }
// #endif
