//
// Image+Named.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

extension Image {
  init(named: NSImage.Name) {
    self.init(nsImage: NSImage(named: named)!)
  }
}
