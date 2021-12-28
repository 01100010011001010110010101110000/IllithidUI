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

// MARK: - CommonActionable

protocol CommonActionable: Votable & Savable {}

// MARK: - Post + CommonActionable

extension Post: CommonActionable {}

// MARK: - Comment + CommonActionable

extension Comment: CommonActionable {}

// MARK: - CommonActionModel

@MainActor
class CommonActionModel<T: CommonActionable>: ObservableObject {
  // MARK: Lifecycle

  init(_ actionable: T) {
    self.actionable = actionable

    vote = VoteDirection(from: actionable)
    voteTask = nil

    saved = actionable.saved
    savedTask = nil
  }

  // MARK: Internal

  @Published var vote: VoteDirection
  @Published var saved: Bool

  func upvote() async throws {
    guard voteTask == nil else { return }

    do {
      switch vote {
      case .up:
        try await actionable.clearVote().value
        vote = .clear
      default:
        try await actionable.upvote().value
        vote = .up
      }
    } catch {
      Illithid.shared.logger.errorMessage("Error voting on \(actionable.name): \(error)")
    }
  }

  func downvote() async throws {
    guard voteTask == nil else { return }

    do {
      switch vote {
      case .down:
        try await actionable.clearVote().value
        vote = .clear
      default:
        try await actionable.downvote().value
        vote = .down
      }
    } catch {
      Illithid.shared.logger.errorMessage("Error voting on \(actionable.name): \(error)")
    }
  }

  func toggleSaved() async throws {
    do {
      if saved {
        try await actionable.unsave().value
        saved = false
      } else {
        try await actionable.save().value
        saved = true
      }
    } catch {
      Illithid.shared.logger.errorMessage("Error toggling saved status on \(actionable.name): \(error)")
    }
  }

  // MARK: Private

  private var actionable: T
  @State private var voteTask: Task<Void, Never>?
  @State private var savedTask: Task<Void, Never>?
}
