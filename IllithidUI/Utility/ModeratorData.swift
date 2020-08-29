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
