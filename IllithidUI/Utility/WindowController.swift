//
// WindowController.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

class WindowController<RootView: View>: NSWindowController {
  convenience init(rootView: RootView, styleMask: NSWindow.StyleMask = [], title: String = "") {
    let hostingController = NSHostingController(rootView: rootView)

    let window = NSWindow()
    window.styleMask = styleMask
    window.contentViewController = hostingController
    window.title = title

    self.init(window: window)
  }
}
