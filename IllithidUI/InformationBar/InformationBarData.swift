//
// InformationBarData.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
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

  private let log = OSLog(subsystem: "com.illithid.IllithidUI.InformationBar",
                          category: .pointsOfInterest)

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
      .sink { [weak self] _ in
        self?.loadMultireddits()
        self?.loadSubscriptions()
      }
  }

  deinit {
    cancelToken?.cancel()
  }

  // TODO: Refactor these to use OrderedSet or a new SortedSet for more efficient insert

  func loadMultireddits() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Multireddits", signpostID: signpostId)
    Illithid.shared.accountManager.currentAccount?.multireddits(queue: .global(qos: .utility)) { result in
      switch result {
      case let .success(multireddits):
        let sortedMultireddits = multireddits.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
        if self.multiReddits != sortedMultireddits {
          DispatchQueue.main.async {
            self.multiReddits = sortedMultireddits
            os_signpost(.end, log: self.log, name: "Load Multireddits", signpostID: signpostId)
          }
        }
      case let .failure(error):
        self.illithid.logger.errorMessage("Failed to fetch multireddits: \(error)")
      }
    }
  }

  func loadSubscriptions() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Subscribed Subreddits", signpostID: signpostId)
    Illithid.shared.accountManager.currentAccount?.subscribedSubreddits(queue: .global(qos: .utility)) { result in
      switch result {
      case let .success(subreddits):
        let sortedSubreddits = subreddits.sorted(by: { $0.displayName.caseInsensitiveCompare($1.displayName) == .orderedAscending })
        if sortedSubreddits != self.subscribedSubreddits {
          DispatchQueue.main.async {
            self.subscribedSubreddits = sortedSubreddits
            os_signpost(.end, log: self.log, name: "Load Subscribed Subreddits", signpostID: signpostId)
          }
        }
      case let .failure(error):
        self.illithid.logger.errorMessage("Error fetching subscribed subreddits: \(error)")
      }
    }
  }
}
