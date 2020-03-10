//
// MultiredditEditView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/08/2020
//

import SwiftUI

import Illithid

struct MultiredditEditView: View {
  @EnvironmentObject var informationBarData: InformationBarData
  @ObservedObject var searchData: SearchData
  @State private var tapped: Bool = false

  let editingId: Multireddit.ID

  init(id: Multireddit.ID, searchData: SearchData) {
    editingId = id
    self.searchData = searchData
  }

  var body: some View {
    let editing = informationBarData.multiReddits.first { $0.id == editingId }!
    return VStack {
      VStack {
        Text(editing.displayName)
          .font(.title)
          .padding(.top)
        Text(editing.descriptionMd)
        Divider()
        VSplitView {
          List {
            ForEach(editing.subreddits) { subreddit in
              Text(subreddit.name)
            }
            .onDelete { indexSet in
              indexSet.forEach { index in
                editing.removeSubreddit(editing.subreddits[index]) { result in
                  switch result {
                  case .success:
                    self.informationBarData.loadMultireddits()
                  case let .failure(error):
                    print("Error removing \(editing.subreddits[index].name) from \(editing.displayName): \(error)")
                  }
                }
              }
            }
          }
          TextField("Search for subreddits to add", text: $searchData.query) {
            _ = self.searchData.search(for: self.searchData.query)
          }
          .padding([.top], 5)
          List {
            ForEach(searchData.subreddits.filter { subreddit in
              !editing.subreddits.map { $0.name }.contains(subreddit.displayName)
            }) { subreddit in
              HStack {
                Text(subreddit.displayName)
                Spacer()
                IllithidButton(action: {
                  editing.addSubreddit(subreddit) { result in
                    switch result {
                    case .success:
                      self.informationBarData.loadMultireddits()
                    case let .failure(error):
                      print("Error adding \(subreddit.displayName) to \(editing.displayName): \(error)")
                    }
                  }
                }, label: "Add to \(editing.displayName)")
              }
            }
          }
        }
      }
    }
    .frame(minWidth: 600, minHeight: 500)
  }
}
