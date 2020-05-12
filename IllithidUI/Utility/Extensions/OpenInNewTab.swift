//
// OpenInNewTab.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/15/20
//

import SwiftUI

extension View {
  func openableInNewTab<Content: View>(id: WindowManager.ID, title: String = "",
                                       @ViewBuilder view: @escaping () -> Content) -> some View {
    gesture(TapGesture().modifiers(.command).onEnded {
      WindowManager.shared.showMainWindowTab(withId: id, title: title) {
        view()
      }
    })
  }
}
