//
//  PreferencesWindowController.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Cocoa
import SwiftUI

class PreferencesWindowController<RootView: View>: NSWindowController {
  convenience init(rootView: RootView) {
    let hostingController = NSHostingController(rootView: rootView.frame(minWidth: 300,
                                                                    minHeight: 400)
    )

    let window = PreferencesWindow()
    window.styleMask = [.titled, .closable, .fullSizeContentView]
    window.contentViewController = hostingController
    window.title = "Illithid Preferences"
    
    self.init(window: window)
  }
}

class PreferencesWindow: NSWindow {}
