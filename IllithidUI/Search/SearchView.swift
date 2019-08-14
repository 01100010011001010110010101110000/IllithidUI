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
  @ObservedObject var searchData: SearchData

  var body: some View {
    VStack {
      TextField("Search Reddit", text: $searchData.query).textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
      List {
        Section(header: Text("Subreddits").font(.headline)) {
          ForEach(searchData.subreddits) { subreddit in
            Text(subreddit.displayName)
          }
        }
        Section(header: Text("Users").font(.headline)) {
          ForEach(searchData.accounts) { account in
            Text(account.name)
          }
        }
        Section(header: Text("Posts").font(.headline)) {
          ForEach(searchData.posts) { post in
            Text(post.title)
          }
        }
      }
    }
  }
}

// #if DEBUG
// struct SearchView_Previews : PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
// }
// #endif
