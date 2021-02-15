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

extension String.StringInterpolation {
  // TODO: Localization support
  mutating func appendInterpolation(_ failure: PostRequirements.ValidationFailure) {
    switch failure {
    case .titleIsRequired:
      appendInterpolation("A title must be present")
    case let .titleTooShort(minLength):
      appendInterpolation("The title must be at least \(minLength) characters long")
    case let .titleTooLong(maxLength):
      appendInterpolation("The title must be at most \(maxLength) characters long")
    case let .titleContainsBannedString(string):
      appendInterpolation("The title cannot contain: \"\(string)\"")
    case let .missingRequiredTitleString(string):
      appendInterpolation("The title must contain: \"\(string)\"")
    case let .missingTitleRegexMatch(regex):
      appendInterpolation("The title must match the RegEx: \"\(regex)\"")

    case .bodyIsForbidden:
      appendInterpolation("A body must not be present")
    case .bodyIsRequired:
      appendInterpolation("A body must be present")
    case let .bodyTooShort(minLength):
      appendInterpolation("The body must be at least \(minLength) characters long")
    case let .bodyTooLong(maxLength):
      appendInterpolation("The body must be at most \(maxLength) characters long")
    case let .bodyContainsBannedString(string):
      appendInterpolation("The body cannot contain: \"\(string)\"")
    case let .missingRequiredBodyString(string):
      appendInterpolation("The body must contain: \"\(string)\"")
    case let .missingBodyRegexMatch(regex):
      appendInterpolation("The body must match the RegEx: \"\(regex)\"")

    case let .invalidLink(link):
      appendInterpolation("The link is invalid: \"\(link.absoluteString)\"")
    case let .domainIsBlacklisted(domain):
      appendInterpolation("\(domain) is not allowed")
    case let .domainIsNotWhitelisted(allowedDomains):
      appendInterpolation("Only links to one of [\(allowedDomains.joined(separator: ","))] are allowed")

    case .missingFlair:
      appendInterpolation("A post flair must be present")
    }
  }
}
