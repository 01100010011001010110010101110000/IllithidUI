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

import Alamofire
import GRDB
import Illithid

// MARK: - SubscribedSubreddit

struct SubscribedSubreddit: Identifiable, Codable {
  // MARK: Lifecycle

  init(from subreddit: Subreddit) {
    id = subreddit.id
    displayName = subreddit.displayName
    url = subreddit.url
    headerImage = subreddit.headerImg
    bannerImage = subreddit.bannerImg
    iconImage = subreddit.iconImg
    over18 = subreddit.over18 ?? false
  }

  // MARK: Internal

  let id: Subreddit.ID
  let displayName: String
  let url: URL
  let headerImage: URL?
  let bannerImage: URL?
  let iconImage: URL?
  let over18: Bool
}

// MARK: FetchableRecord, TableRecord, PersistableRecord

extension SubscribedSubreddit: FetchableRecord, TableRecord, PersistableRecord {
  public private(set) static var databaseTableName: String = "subscribedSubreddits"
}

// MARK: PostProvider

extension SubscribedSubreddit: PostProvider {
  var isNsfw: Bool {
    over18
  }

  func posts(sortBy _: PostSort, location _: Location?, topInterval _: TopInterval?, parameters _: ListingParameters, queue _: DispatchQueue, completion _: @escaping (Result<Listing, AFError>) -> Void) -> DataRequest {
    fatalError()
  }
}
