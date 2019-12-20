//
//  InformationBarData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/20/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import os.log
import SwiftUI

import Illithid

final class InformationBarData: ObservableObject {
  private var illithid: Illithid = .shared
  private var defaults: UserDefaults = .standard
  private var decoder = JSONDecoder()
  private var encoder = JSONEncoder()
  private var cancelToken: AnyCancellable?

  private let log = OSLog(subsystem: "com.illithid.IllithidUI", category: .pointsOfInterest)

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

    // Loading the subscriptions takes a few seconds if the user has many, so use a high period
    cancelToken = Timer.publish(every: 30.0, on: .main, in: .common)
      .autoconnect()
      .receive(on: DispatchQueue.global(qos: .background))
      .sink { [weak self] _ in
        self?.loadMultireddits()
        self?.loadSubscriptions()
      }
  }

  deinit {
    cancelToken?.cancel()
  }

  func loadMultireddits() {
    let signpostId = OSSignpostID(log: self.log)
    os_signpost(.begin, log: self.log, name: "Load Multireddits", signpostID: signpostId)
    Illithid.shared.accountManager.currentAccount!.multireddits { multireddits in
      let sortedMultireddits = multireddits.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
      if self.multiReddits != sortedMultireddits {
        self.multiReddits = sortedMultireddits
      }
      os_signpost(.end, log: self.log, name: "Load Multireddits", signpostID: signpostId)
    }
  }

  func loadSubscriptions() {
    let signpostId = OSSignpostID(log: self.log)
    os_signpost(.begin, log: self.log, name: "Load Subscribed Subreddits", signpostID: signpostId)
    Illithid.shared.accountManager.currentAccount!.subscribedSubreddits { subreddits in
      let sortedSubreddits = subreddits.sorted(by: { $0.displayName.caseInsensitiveCompare($1.displayName) == .orderedAscending })
      if sortedSubreddits != self.subscribedSubreddits {
        self.subscribedSubreddits = sortedSubreddits
      }
      os_signpost(.end, log: self.log, name: "Load Subscribed Subreddits", signpostID: signpostId)
    }
  }
}
