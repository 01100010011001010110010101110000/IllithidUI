//
// SubredditsData.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import Foundation

import Illithid

final class SubredditData: ObservableObject {
  @Published var subreddits: [Subreddit] = []
}
