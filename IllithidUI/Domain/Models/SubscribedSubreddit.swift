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

    permitsSelfPosts = subreddit.permitsSelfPosts
    permitsImagePosts = subreddit.permitsImagePosts
    permitsGalleryPosts = subreddit.permitsGalleryPosts
    permitsVideoPosts = subreddit.permitsVideoPosts
    permitsGifPosts = subreddit.permitsGifPosts
    permitsLinkPosts = subreddit.permitsLinkPosts
    permitsPollPosts = subreddit.permitsPollPosts
  }

  // MARK: Internal

  let id: Subreddit.ID
  let displayName: String
  let url: URL
  let headerImage: URL?
  let bannerImage: URL?
  let iconImage: URL?
  let over18: Bool

  let permitsSelfPosts: Bool
  let permitsImagePosts: Bool
  let permitsGalleryPosts: Bool
  let permitsVideoPosts: Bool
  let permitsGifPosts: Bool
  let permitsLinkPosts: Bool
  let permitsPollPosts: Bool
}

// MARK: FetchableRecord, TableRecord, PersistableRecord

extension SubscribedSubreddit: FetchableRecord, TableRecord, PersistableRecord {
  public private(set) static var databaseTableName: String = "subscribedSubreddits"
}

// MARK: PostProvider, PostAcceptor

extension SubscribedSubreddit: PostProvider, PostAcceptor {
  var uploadTarget: String {
    displayName
  }

  var isNsfw: Bool {
    over18
  }

  public var postsPath: String {
    "/r/\(displayName)"
  }
}
