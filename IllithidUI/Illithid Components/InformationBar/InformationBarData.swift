// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Combine
import Foundation
import os.log
import SwiftUI

import Illithid

final class InformationBarData: ObservableObject {
  // MARK: Lifecycle

  init() {
    decoder.dateDecodingStrategy = .secondsSince1970
    encoder.dateEncodingStrategy = .secondsSince1970

    if let subscribedData = defaults.data(forKey: "subscribedSubreddits"),
       let subreddits = try? decoder.decode([Subreddit].self, from: subscribedData) {
      subscribedSubreddits = subreddits
    } else {
      subscribedSubreddits = []
    }

    if let multiData = defaults.data(forKey: "multireddits"),
       let multis = try? decoder.decode([Multireddit].self, from: multiData) {
      multireddits = multis
    } else {
      multireddits = []
    }
//    listen()
  }

  deinit {
    while !cancelTokens.isEmpty {
      cancelTokens.popLast()?.cancel()
    }
  }

  // MARK: Internal

  @Published var subscribedSubreddits: [Subreddit] {
    didSet {
      guard let data = try? encoder.encode(subscribedSubreddits) else { return }
      defaults.set(data, forKey: "subscribedSubreddits")
    }
  }

  @Published var multireddits: [Multireddit] {
    didSet {
      guard let data = try? encoder.encode(multireddits) else { return }
      defaults.set(data, forKey: "multireddits")
    }
  }

  func loadAccountData() {
    loadMultireddits()
    loadSubscriptions()
  }

  func loadMultireddits() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Multireddits", signpostID: signpostId)
    accountManager.currentAccount?.multireddits(queue: Self.queue) { result in
      defer {
        os_signpost(.end, log: self.log, name: "Load Multireddits", signpostID: signpostId)
      }
      switch result {
      case let .success(multireddits):
        let sortedMultireddits = multireddits.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
        if self.multireddits != sortedMultireddits {
          DispatchQueue.main.async {
            self.multireddits = sortedMultireddits
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
    accountManager.currentAccount?.subscribedSubreddits(queue: Self.queue) { result in
      defer {
        os_signpost(.end, log: self.log, name: "Load Subscribed Subreddits", signpostID: signpostId)
      }
      switch result {
      case let .success(subreddits):
        let sortedSubreddits = subreddits.sorted(by: { $0.displayName.caseInsensitiveCompare($1.displayName) == .orderedAscending })
        if sortedSubreddits != self.subscribedSubreddits {
          DispatchQueue.main.async {
            self.subscribedSubreddits = sortedSubreddits
          }
        }
      case let .failure(error):
        self.illithid.logger.errorMessage("Error fetching subscribed subreddits: \(error)")
      }
    }
  }

  func displayName(forId id: String) -> String? {
    if id == "__account__" { return "Account" }
    else if id == "__search__" { return "Search" }
    else if let page = FrontPage.allCases.first(where: { $0.id == id }) { return page.displayName }
    else if let multireddit = multireddits.first(where: { $0.id == id }) { return multireddit.displayName }
    else if let subreddit = subscribedSubreddits.first(where: { $0.id == id }) { return subreddit.displayName }
    else { return nil }
  }

  // MARK: Private

  private static let queue = DispatchQueue(label: "com.flayware.IllithidUI.InformationBar", qos: .background)

  private let illithid: Illithid = .shared
  private let accountManager: AccountManager = Illithid.shared.accountManager

  private let defaults: UserDefaults = .standard
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.InformationBar",
                          category: .pointsOfInterest)

  private var cancelTokens: [AnyCancellable] = []

  private func listen() {
    let token = accountManager.$currentAccount
      .removeDuplicates()
      .sink(receiveCompletion: { [weak self] completion in
        switch completion {
        case .finished:
          self?.illithid.logger.infoMessage("Finished fetching accounts from the global account manager")
        case let .failure(error):
          self?.illithid.logger.infoMessage("Error fetching accounts from the global account manager: \(error)")
        }
      }) { [weak self] account in
        self?.clearAccountData()
        if account != nil {
          self?.loadAccountData()
        }
      }
    cancelTokens.append(token)
  }

  private func clearAccountData() {
    clearSubscriptions()
    clearMultireddits()
  }

  private func clearSubscriptions() {
    subscribedSubreddits.removeAll()
  }

  private func clearMultireddits() {
    multireddits.removeAll()
  }
}
