//
// WindowController.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

final class WindowController: NSWindowController {
  @IBAction override func newWindowForTab(_: Any?) {
    WindowManager.shared.newRootWindow()
  }
}

final class Window<Content: View>: NSWindow {
  convenience init(styleMask: NSWindow.StyleMask = [], title: String = "", @ViewBuilder rootView: () -> Content) {
    self.init()
    self.styleMask = styleMask
    self.title = title
    contentViewController = NSHostingController(rootView: rootView())
  }
}
