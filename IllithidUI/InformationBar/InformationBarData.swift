//
//  InformationBarData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/20/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class InformationBarData: ObservableObject {
  private var illithid: Illithid = .shared
  private var defaults: UserDefaults = .standard
  private var decoder = JSONDecoder()
  private var encoder = JSONEncoder()

  @Published var subscribedSubreddits: [Subreddit] {
    didSet {
      guard let data = try? encoder.encode(subscribedSubreddits) else { return }
      defaults.set(data, forKey: "subscribedSubreddits")
    }
  }

  @Published var multiReddits: [Multireddit] {
    didSet {
      guard let data = try? encoder.encode(multiReddits) else { return }
      defaults.set(data, forKey: "multireddits")
    }
  }

  init() {
    decoder.dateDecodingStrategy = .secondsSince1970
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    encoder.dateEncodingStrategy = .secondsSince1970
    encoder.keyEncodingStrategy = .convertToSnakeCase

    if let subscribedData = defaults.data(forKey: "subscribedSubreddits"),
      let subreddits = try? decoder.decode([Subreddit].self, from: subscribedData) {
      subscribedSubreddits = subreddits
    } else {
      subscribedSubreddits = []
    }

    if let multiData = defaults.data(forKey: "multireddits"),
      let multis = try? decoder.decode([Multireddit].self, from: multiData) {
      multiReddits = multis
    } else {
      multiReddits = []
    }

    if multiReddits.isEmpty {
      loadMultireddits()
    }
    if subscribedSubreddits.isEmpty {
      loadSubscriptions()
    }
  }

  // TODO: Periodic subscription and multireddit refresh

  func loadMultireddits() {
    Illithid.shared.accountManager.currentAccount!.multireddits { multireddits in
      self.multiReddits = multireddits
    }
  }

  func loadSubscriptions() {
    Illithid.shared.accountManager.currentAccount!.subscribedSubreddits { subreddits in
      self.subscribedSubreddits = subreddits.sorted(by: { $0.displayName.caseInsensitiveCompare($1.displayName) == .orderedAscending })
    }
  }
}
