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
import os.log
import SwiftUI

import Alamofire
import Illithid

final class PostListData: ObservableObject {
  @Published var posts: [Post] = []

  let provider: PostProvider

  init(provider: PostProvider) {
    self.provider = provider
  }

  private var postListingParams: ListingParameters = .init()
  private var exhausted: Bool = false
  private var loading: Bool = false
  private let illithid: Illithid = .shared
  private let log = OSLog(subsystem: "com.flayware.IllithidUI.posts",
                          category: .pointsOfInterest)
  private var requests: [DataRequest] = []

  func loadPosts(sort: PostSort, topInterval: TopInterval) {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Posts", signpostID: signpostId)
    if !exhausted, !loading {
      loading = true
      let request = provider.posts(sortBy: sort, location: nil, topInterval: topInterval,
                                   parameters: postListingParams, queue: .main) { result in
        switch result {
        case let .success(listing):
          if let anchor = listing.after { self.postListingParams.after = anchor }
          else { self.exhausted = true }
          self.posts.append(contentsOf: listing.posts)
        case let .failure(error):
          self.illithid.logger.errorMessage("Failed to load posts: \(error)")
        }
        self.loading = false
        os_signpost(.end, log: self.log, name: "Load Posts", signpostID: signpostId)
      }
      requests.append(request)
    }
  }

  func reload(sort: PostSort, topInterval: TopInterval) {
    cancel()
    exhausted = false
    posts.removeAll(keepingCapacity: true)
    postListingParams = .init()
    loadPosts(sort: sort, topInterval: topInterval)
  }

  func cancel() {
    while !requests.isEmpty {
      requests.popLast()?.cancel()
    }
  }
}
