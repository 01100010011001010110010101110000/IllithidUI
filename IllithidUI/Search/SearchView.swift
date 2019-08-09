//
//  SearchView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 7/8/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

struct SearchView: View {
  @ObservedObject var searchData: SearchData

  let reddit: RedditClientBroker

  init(reddit: RedditClientBroker) {
    self.reddit = reddit
    searchData = .init(reddit: reddit)
  }

  var body: some View {
    VStack {
      TextField("Search Reddit", text: $searchData.query).textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
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
