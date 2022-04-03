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

import Foundation
import SwiftUI

import Alamofire
import Illithid

// MARK: - MockPostListView

struct MockPostListView: View {
  // MARK: Internal

  var body: some View {
    PostListView(from: Self.listing)
  }

  // MARK: Private

  private static let listing: Listing = {
    let mockListingPath = Bundle.main.path(forResource: "frontpage_best", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: mockListingPath))
    return try! JSONDecoder().decode(Listing.self, from: data)
  }()
}

// MARK: - FakePostProvider

struct FakePostProvider: PostProvider {
  let id: String = "__fakepostprovider__"

  let isNsfw: Bool = false

  let displayName: String = "Fake Post Provider"

  var postsPath: String {
    "/r/\(displayName)"
  }

  func posts(sortBy _: PostSort, location _: Location?, topInterval _: TopInterval?, parameters _: ListingParameters, queue _: DispatchQueue, completion _: @escaping (Result<Listing, AFError>) -> Void) -> DataRequest {
    Session.default.request(URL(string: "https://google.com")!)
  }
}
