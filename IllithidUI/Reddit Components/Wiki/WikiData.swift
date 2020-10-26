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

import Illithid

final class WikiData: ObservableObject {
  // MARK: Lifecycle

  init(subreddit: Subreddit) {
    self.subreddit = subreddit
  }

  deinit {
    cancelTokens.forEach { $0.cancel() }
  }

  // MARK: Internal

  @Published var pages: [URL] = []

  let subreddit: Subreddit
  var cancelTokens: [AnyCancellable] = []

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
}
