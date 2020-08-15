//
// SearchView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/9/20
//

import SwiftUI

import Illithid

struct SearchView: View {
  @StateObject var searchData: SearchData = .init()

  @State private var selection: Subreddit? = nil
  @State private var blur: Bool = false

  let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 320)),
  ]

  var prompt: String {
    if searchData.query.isEmpty { return "Make a search" }
    else if searchData.suggestions.isEmpty { return "No subreddits found" }
    else { return "Open a subreddit" }
  }

  func openModal(for subreddit: Subreddit) {
    withAnimation(.modal) { selection = subreddit }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  func closeModal() {
    withAnimation(.modal) { selection = nil }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = false }
    }
  }

  var body: some View {
    ZStack {
      VStack {
        TextField("Search Reddit", text: $searchData.query) {
          // Allows the user to force a search for a string shorter than 3 characters
          _ = self.searchData.search(for: self.searchData.query)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()

        ScrollView {
          LazyVGrid(columns: columns) {
            ForEach(searchData.suggestions) { suggestion in
              SubredditSuggestionLabel(suggestion: suggestion)
                .onTapGesture(count: 1, perform: {
                  openModal(for: suggestion)
                })
            }
          }
          .padding(10)
        }
      }
      .disabled(selection != nil)
      .blur(radius: blur ? 8 : 0)
      .zIndex(1)

      if let subreddit = selection {
        RoundedRectangle(cornerRadius: 8)
          .onMouseGesture(mouseDown: {
            closeModal()
          }, mouseUp: {})
          .foregroundColor(.clear)
          .zIndex(2)

        PostListView(postContainer: subreddit)
          .clipShape(ContainerRelativeShape())
          .padding(20)
          .shadow(radius: 10)
          .zIndex(3)
      }
    }
  }
}

// TODO: Pull this modal view with blurred background into something reusable
private extension Animation {
  static let modal: Animation = .interactiveSpring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.25)
  static let blur: Animation = .linear(duration: 0.25)
}

// #if DEBUG
// struct SearchView_Previews : PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
// }
// #endif
