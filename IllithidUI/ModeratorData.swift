//
// ModeratorData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/05/2020
//

import SwiftUI

import Illithid

final class ModeratorData: ObservableObject {
  static let shared: ModeratorData = .init()

  @Published var moderators: [String: [Moderator]] = [:]
  private var loading: Set<String> = []

  private init() {}

  func loadModerators(for subredditName: String) {
    if moderators.index(forKey: subredditName) == nil, !loading.contains(subredditName) {
      loading.insert(subredditName)
      Illithid.shared.moderatorsOf(displayName: subredditName) { result in
        result.map { self.moderators[subredditName] = $0 }
        self.loading.remove(subredditName)
      }
    }
  }
}
