//
// WikiData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/18/20
//

import Combine
import Foundation

import Illithid

final class WikiData: ObservableObject {
  @Published var pages: [URL] = []

  let subreddit: Subreddit
  var cancelTokens: [AnyCancellable] = []

  init(subreddit: Subreddit) {
    self.subreddit = subreddit
  }

  func fetchWikiPages() {
    let token = subreddit.wikiPages()
      .map { $0.pageLinks }
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          Illithid.shared.logger.debugMessage("Finished fetching wiki pages for \(self.subreddit.displayName): \(completion)")
        case let .failure(error):
          Illithid.shared.logger.errorMessage("Error fetching wiki pages for \(self.subreddit.displayName): \(error)")
        }
      }, receiveValue: { value in
        self.pages = value
      })
    cancelTokens.append(token)
  }

  deinit {
    cancelTokens.forEach { $0.cancel() }
  }
}
