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
import SwiftUI

extension Image {
  init(named: NSImage.Name) {
    self.init(nsImage: NSImage(named: named)!)
  }
}

extension NSImage.Name {
  static let arrowDown = NSImage.Name("arrow.down")
  static let arrowUp = NSImage.Name("arrow.up")
  static let bookmark = NSImage.Name("bookmark.fill")
  static let eyeSlash = NSImage.Name("eye.slash")
  static let search = NSImage.Name("magnifyingglass")
  static let textBubble = NSImage.Name("text.bubble")
  static let textBubbleFilled = NSImage.Name("text.bubble.fill")
  static let checkmark = NSImage.Name("check")
  static let clock = NSImage.Name("clock")
  static let flag = NSImage.Name("flag.fill")
  static let arrowDownRightUpLeft = NSImage.Name("expand.alt")
  static let menuBars = NSImage.Name("bars")
  static let lock = NSImage.Name("lock")
  static let mapPin = NSImage.Name("map.pin")
  static let book = NSImage.Name("book")
  static let rssFeed = NSImage.Name("rss")

  // Browsers
  static let chrome = NSImage.Name("chrome")
  static let compass = NSImage.Name("compass")
  static let firefox = NSImage.Name("firefox")
  static let safari = NSImage.Name("compass")

  // Website icons
  static let redditSquare = NSImage.Name("reddit.square")
}
