//
//  WindowController.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/18/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
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
