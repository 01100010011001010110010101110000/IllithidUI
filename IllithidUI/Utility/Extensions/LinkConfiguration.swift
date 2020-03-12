//
//  LinkConfiguration.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 3/11/20.
//  Copyright © 2020 Tyler Gregory. All rights reserved.
//

import AppKit
import Foundation

extension NSWorkspace.OpenConfiguration {
  static var linkConfiguration: NSWorkspace.OpenConfiguration {
    let preferences: PreferencesData = .shared
    let config = NSWorkspace.OpenConfiguration()
    config.activates = preferences.openLinksInForeground
    return config
  }
}
