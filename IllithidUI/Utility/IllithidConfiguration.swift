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

import AppKit
import Foundation

import Illithid
import OAuthSwift

struct IllithidConfiguration: ClientConfiguration {
  /// Application OAuth2 callback URL
  let redirectURI = URL(string: "illithid://oauth2/callback")!
  /// The version of Illithid
  let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
  /// The author's Reddit username
  let author = "Tyler1-66"

  let consumerKey = "f7SCggcYGArzHg"

  let consumerSecret = ""

  let scope = "identity edit account creddits mysubreddits read vote wikiread history save flair report livemanage modconfig modcontributors modflair modlog modmail modothers modposts modself modwiki submit subscribe wikiedit structuredstyles privatemessages"

  let responseType: OAuthResponseType = .code

  let duration: Duration = .permanent
}
