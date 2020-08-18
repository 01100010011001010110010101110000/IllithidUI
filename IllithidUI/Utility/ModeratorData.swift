//
// ModeratorData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

import Illithid

final class ModeratorData: ObservableObject {
  @Published private(set) var moderators: [String: [Moderator]] = [:]
  private var loading: Set<String> = []

  private init() {}

  static let shared: ModeratorData = .init()

  func isModerator(username: String, ofSubreddit subredditName: String) -> Bool {
    guard let mods = moderators[subredditName] else {
      loadModerators(for: subredditName)
      return false
    }
    return mods.contains { $0.name == username }
  }

  private func loadModerators(for subredditName: String) {
    if moderators.index(forKey: subredditName) == nil, !loading.contains(subredditName) {
      loading.insert(subredditName)
      _ = Illithid.shared.moderatorsOf(displayName: subredditName) { result in
        _ = result.map { self.moderators[subredditName] = $0 }
        self.loading.remove(subredditName)
      }
    }
  }
}
