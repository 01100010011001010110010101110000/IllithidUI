//
// LinkConfiguration.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
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
