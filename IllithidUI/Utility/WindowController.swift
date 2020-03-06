//
// WindowController.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

final class WindowController<RootView: View>: NSWindowController {
  convenience init(styleMask: NSWindow.StyleMask = [], title: String = "", @ViewBuilder rootView: () -> RootView) {
    let hostingController = NSHostingController(rootView: rootView())

    let window = NSWindow()
    window.styleMask = styleMask
    window.contentViewController = hostingController
    window.title = title

    self.init(window: window)
  }

  convenience init(rootView: RootView, styleMask: NSWindow.StyleMask = [], title: String = "") {
    let hostingController = NSHostingController(rootView: rootView)

    let window = NSWindow()
    window.styleMask = styleMask
    window.contentViewController = hostingController
    window.title = title

    self.init(window: window)
  }
}

final class Window<RootView: View>: NSWindow {
  convenience init(styleMask: NSWindow.StyleMask = [], title: String = "", @ViewBuilder rootView: () -> RootView) {
    self.init()
    self.styleMask = styleMask
    self.title = title
    self.contentViewController = NSHostingController(rootView: rootView())
  }
}
