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
  @State var query: String = ""
  @ObjectBinding var queryResults: SearchData = .init()

  let reddit: RedditClientBroker

  var body: some View {
    VStack {
      //Debounce appears to be bugged, will leave this aside for now
      TextField($query, placeholder: Text("Search Reddit")).textFieldStyle(.roundedBorder)
        .onReceive(query.publisher().collect().map { String($0) }.debounce(for: 0.3, scheduler: RunLoop.main)) { changedQuery in
          print(changedQuery)
      }
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
