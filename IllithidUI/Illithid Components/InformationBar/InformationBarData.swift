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
      multiReddits = multis
    } else {
      multiReddits = []
    }
  }

  // MARK: Internal

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

  func loadMultireddits() {
    let signpostId = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "Load Multireddits", signpostID: signpostId)
    Illithid.shared.accountManager.currentAccount?.multireddits(queue: Self.queue) { result in
      defer {
        os_signpost(.end, log: self.log, name: "Load Multireddits", signpostID: signpostId)
      }
      switch result {
      case let .success(multireddits):
        let sortedMultireddits = multireddits.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
        if self.multiReddits != sortedMultireddits {
          DispatchQueue.main.async {
            self.multiReddits = sortedMultireddits
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
    Illithid.shared.accountManager.currentAccount?.subscribedSubreddits(queue: Self.queue) { result in
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

  // MARK: Private

  private static let queue = DispatchQueue(label: "com.flayware.IllithidUI.InformationBar", qos: .background)

  private var illithid: Illithid = .shared
  private var defaults: UserDefaults = .standard
  private var decoder = JSONDecoder()
  private var encoder = JSONEncoder()

  private let log = OSLog(subsystem: "com.flayware.IllithidUI.InformationBar",
                          category: .pointsOfInterest)
}
