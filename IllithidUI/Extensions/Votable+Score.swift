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

import Illithid

extension Votable {
  /// Calculates the score of the `Votable`, given an external `VoteDirection` tracking the vote in the current session
  ///
  /// - Parameter ballot: External `VoteDirection` state
  /// - Returns: The calculated score
  func score(given ballot: VoteDirection) -> Int {
    // If the model already accounts for the current session's vote, return the score directly
    if isSyncedWithModel(ballot: ballot) {
      return ups
    } else {
      return ups + ballot.rawValue
    }
  }

  private func isSyncedWithModel(ballot: VoteDirection) -> Bool {
    let ballotForCurrentModel = VoteDirection(from: self)
    return ballot == ballotForCurrentModel
  }
}
