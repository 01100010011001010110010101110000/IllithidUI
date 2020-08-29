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
import os.log

import Illithid

final class SubredditListData: ObservableObject {
  @Published var subreddits: [Subreddit] = []

  let illithid: Illithid = .shared
  private var listingParams: ListingParameters = .init()
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.subreddits",
                          category: .pointsOfInterest)

  func loadSubreddits() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Subreddits", signpostID: signpostId)
    illithid.subreddits(params: listingParams) { result in
      switch result {
      case let .success(listing):
        if let anchor = listing.after { self.listingParams.after = anchor }
        self.subreddits.append(contentsOf: listing.subreddits)
        os_signpost(.end, log: self.log, name: "Load Subreddits")
      case let .failure(error):
        self.illithid.logger.errorMessage("Error fetching subreddit data: \(error)")
      }
    }
  }
}
