//
// IllithidConfiguration.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

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
  let author = "Tyler1-66" // swiftlint:disable:this identifier_name

  let consumerKey = "f7SCggcYGArzHg"

  let consumerSecret = ""

  let scope = "identity edit account creddits mysubreddits read vote wikiread history save flair report livemanage modconfig modcontributors modflair modlog modmail modothers modposts modself modwiki submit subscribe wikiedit structuredstyles privatemessages"

  let responseType: OAuthResponseType = .code

  let duration: Duration = .permanent
}
