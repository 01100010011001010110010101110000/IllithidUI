//
//  IllithidConfiguration.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/13/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import AppKit
import Foundation

import Illithid
import OAuthSwift

struct IllithidConfiguration: ClientConfiguration {
  // MARK: OAuth2 parameters

  lazy var oauthParameters: OAuthSwift.ConfigParameters = {
    return [
      "consumerKey": consumerKey,
      "consumerSecret": consumerSecret,
      "duration": duration.rawValue,
      "authorizeUrl": RedditClientBroker.authorizeEndpoint.absoluteString,
      "accessTokenUrl": RedditClientBroker.tokenEndpoint.absoluteString,
      "responseType": responseType.rawValue,
      "scope": scope
    ]
    }()

  /// Application OAuth2 callback URL
  let redirectURI = URL(string: "illithid://oauth2/callback")!
  /// The version of Illithid
  let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
  /// The author's Reddit username
  let author = "Tyler1-66" // swiftlint:disable:this identifier_name

  let consumerKey = "f7SCggcYGArzHg"

  let consumerSecret = ""

  let scope = "identity mysubreddits read vote wikiread"

  let responseType: OAuthResponseType = .code

  let duration: Duration = .permanent

  internal let defaults = UserDefaults.standard
}
