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

import Foundation

import Illithid

extension Post {
  public var relativePostTime: String {
    DateComponentsFormatter.ShortFormatter.string(from: createdUtc, to: Date()) ?? "UNKNOWN"
  }

  public var absolutePostTime: String {
    DateFormatter.LongFormatter.string(from: createdUtc)
  }
}

extension Comment {
  public var relativeCommentTime: String {
    DateComponentsFormatter.ShortFormatter.string(from: createdUtc, to: Date()) ?? "UNKNOWN"
  }
}

extension DateComponentsFormatter {
  static let ShortFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .abbreviated
    formatter.allowsFractionalUnits = true
    formatter.zeroFormattingBehavior = .dropAll
    formatter.allowedUnits = [.month, .day, .hour, .minute, .year]
    return formatter
  }()
}

extension DateFormatter {
  static let LongFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long
    return formatter
  }()
}
