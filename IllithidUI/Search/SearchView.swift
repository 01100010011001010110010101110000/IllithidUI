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
      NavigationView {
        List {
          if !searchData.subreddits.isEmpty {
            Section(header: Text("Subreddits").font(.headline)) {
              ForEach(searchData.subreddits) { subreddit in
                NavigationLink(destination: PostListView(postsData: .init(), subreddit: subreddit)) {
                  Text(subreddit.displayName)
                }
              }
            }
          }

          if !searchData.accounts.isEmpty {
            Section(header: Text("Users").font(.headline)) {
              ForEach(searchData.accounts) { account in
                Text(account.name)
              }
            }
          }

          if !searchData.posts.isEmpty {
            Section(header: Text("Posts").font(.headline)) {
              ForEach(searchData.posts) { post in
                NavigationLink(destination: CommentsView(post: post)) {
                  Text(post.title)
                }
              }
            }
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
