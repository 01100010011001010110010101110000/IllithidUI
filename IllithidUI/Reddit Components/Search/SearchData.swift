// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Combine
import Foundation
import SwiftUI

import Alamofire
import Illithid

final class SearchData: ObservableObject {
  // MARK: Lifecycle

  init(for targets: Set<SearchType> = [.post]) {
    searchTargets = targets
    let queryPublisher = $query.share()
    let searchToken = queryPublisher
      .filter { $0.count >= 3 }
      .debounce(for: 0.3, scheduler: RunLoop.current)
      .removeDuplicates()
      .sink { [weak self] searchFor in
        guard let self = self else { return }
        self.request?.cancel()
        self.request = self.search(for: searchFor)
      }
    cancelBag.append(searchToken)
    let autocompleteToken = queryPublisher
      .filter { $0.count >= 3 }
      .debounce(for: 0.2, scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] toComplete in
        guard let self = self else { return }
        self.autocompleteRequest?.cancel()
        self.autocompleteRequest = self.illithid.completeSubreddits(startsWith: toComplete, limit: 10) { result in
          switch result {
          case let .success(subreddits):
            self.suggestions = subreddits
          case let .failure(error):
            self.illithid.logger.errorMessage("Unable to autocomplete query: \(error)")
          }
        }
      }
    cancelBag.append(autocompleteToken)
  }

  deinit {
    autocompleteRequest?.cancel()
    request?.cancel()
    cancelBag.cancel()
  }

  // MARK: Internal

  @Published var query: String = ""
  /// Subreddits suggested by the search endpoint
  @Published var subreddits: [Subreddit] = []
  @Published var posts: [Post] = []
  /// Subreddits suggested by the autocompletion endpoint
  @Published var suggestions: [Subreddit] = []

  let illithid: Illithid = .shared
  let searchTargets: Set<SearchType>

  func search(for searchText: String) -> DataRequest {
    illithid.search(for: searchText, resultTypes: searchTargets) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case let .success(listings):
        self.clearData()
        // TODO: Optimize this
        for listing in listings {
          self.subreddits.append(contentsOf: listing.subreddits)
          self.posts.append(contentsOf: listing.posts)
        }
      case let .failure(error):
        self.illithid.logger.errorMessage("Failed to search: \(error)")
      }
    }
  }

  func clearData() {
    suggestions.removeAll(keepingCapacity: true)
    subreddits.removeAll(keepingCapacity: true)
    posts.removeAll(keepingCapacity: true)
  }

  func clearQueryText() {
    query.removeAll()
  }

  /// Resets all data, clearing the query text and all search results
  func reset() {
    clearData()
    clearQueryText()
  }

  // MARK: Private

  private var cancelBag: [AnyCancellable] = []
  private var request: DataRequest?
  private var autocompleteRequest: DataRequest?
}
