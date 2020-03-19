//
// Image+Named.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/19/2020
//

import SwiftUI

extension Image {
  init(named: NSImage.Name) {
    self.init(nsImage: NSImage(named: named)!)
  }
}
