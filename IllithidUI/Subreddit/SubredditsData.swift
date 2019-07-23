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
  let willChange = PassthroughSubject<Void, Never>()

  var subreddits: [Subreddit] = [] {
    willSet {
      willChange.send()
    }
  }
}
