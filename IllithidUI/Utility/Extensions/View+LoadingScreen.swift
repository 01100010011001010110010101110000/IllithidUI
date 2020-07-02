//
// View+LoadingScreen.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/1/20
//

import Foundation
import SwiftUI

extension View {
  func loadingScreen(isLoading: Bool, title: String) -> some View {
    overlay(
      ProgressView(title)
        .opacity(isLoading ? 1 : 0)
    )
  }

  func loadingScreen<Content: View>(isLoading: Bool, @ViewBuilder _ label: () -> Content) -> some View {
    overlay(
      ProgressView(label: label)
        .opacity(isLoading ? 1 : 0)
    )
  }
}
