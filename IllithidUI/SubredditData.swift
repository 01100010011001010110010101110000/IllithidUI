//
//  SubredditsData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/6/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class SubredditData: BindableObject {
  let didChange = PassthroughSubject<SubredditData, Never>()

  var subreddits: [Subreddit] = [] {
    didSet {
      didChange.send(self)
    }
  }
}
