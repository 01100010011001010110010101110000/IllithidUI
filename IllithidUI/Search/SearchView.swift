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
  @ObservedObject var queryResults: SearchData = .init()

  let reddit: RedditClientBroker

  var body: some View {
    VStack {
      //Debounce appears to be bugged, will leave this aside for now
      TextField("Search Reddit", text: $query).textFieldStyle(RoundedBorderTextFieldStyle())
        .onReceive(query.publisher.collect().map { String($0) }.debounce(for: 0.3, scheduler: RunLoop.main)) { query in
          print(query)
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
