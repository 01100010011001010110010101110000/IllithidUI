//
// Created by Tyler Gregory on 12/31/20.
// Copyright (c) 2020 Tyler Gregory. All rights reserved.
//

import Illithid

// All the below force casts are fine; the guard tests for the subreddit being private, so they will be present
extension Subreddit {
  /// Whether the subreddit allows self, i.e. text, posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsSelfPosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .link
  }

  /// Whether the subreddit allows link posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsLinkPosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .`self`
  }

  /// Whether the subreddit allows image posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsImagePosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .`self` && allowImages!
  }

  /// Whether the subreddit allows gallery posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsGalleryPosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .`self` && allowGalleries!
  }

  /// Whether the subreddit allows video posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsVideoPosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .`self` && allowVideos
  }

  /// Whether the subreddit allows GIF posts
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsGifPosts: Bool? {
    guard let type = submissionType else { return nil }
    return type != .`self` && allowVideogifs
  }

  /// Whether the subreddit allows polls
  /// - Note: `nil` if the subreddit is private and the current user context does not have access
  var allowsPollPosts: Bool? {
    allowPolls!
  }
}