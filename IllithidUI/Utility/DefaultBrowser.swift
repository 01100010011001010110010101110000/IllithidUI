//
//  DefaultBrowser.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 2/26/20.
//  Copyright © 2020 Tyler Gregory. All rights reserved.
//

import Cocoa
import Foundation

enum DefaultBrowser {
  /// The default browser at application startup
  static var atStartup: DefaultBrowser = {
    guard let bundleUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://reddit.com")!) else { return .safari }
    guard let identifier = Bundle(url: bundleUrl)?.bundleIdentifier else { return .safari }
    
    switch identifier {
    case "com.apple.Safari":
      return .safari
    case "org.mozilla.firefox":
      return .firefox
    case "com.google.Chrome":
      return .chrome
    case "com.microsoft.edgemac":
      return .edge
    case "org.torproject.torbrowser":
      return .tor
    default:
      return .safari
    }
  }()

  case safari
  case edge
  case opera
  case chrome
  case tor
  case firefox
}
