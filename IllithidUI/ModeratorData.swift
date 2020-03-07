//
// ModeratorData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/05/2020
//

import SwiftUI

import Illithid

final class ModeratorData: ObservableObject {
  @Published private(set) var moderators: [String: [Moderator]] = [:]
  private var loading: Set<String> = []

  init() {}

  func loadModerators(for subredditName: String) {
    if moderators.index(forKey: subredditName) == nil, !loading.contains(subredditName) {
      loading.insert(subredditName)
      _ = Illithid.shared.moderatorsOf(displayName: subredditName) { result in
        _ = result.map { self.moderators[subredditName] = $0 }
        self.loading.remove(subredditName)
      }
    }
  }
}
