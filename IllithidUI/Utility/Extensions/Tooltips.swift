//
// Tooltips.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import SwiftUI

extension View {
  /// Overlays this view with a view that provides a tooltip with the given string.
  func tooltip(_ tooltip: String?) -> some View {
    overlay(TooltipView(tooltip: tooltip))
  }
}

private struct TooltipView: NSViewRepresentable {
  let tooltip: String?

  func makeNSView(context _: NSViewRepresentableContext<TooltipView>) -> NSView {
    let view = NSView()
    view.toolTip = tooltip
    return view
  }

  func updateNSView(_: NSView, context _: NSViewRepresentableContext<TooltipView>) {}
}

struct Tooltips_Previews: PreviewProvider {
  static var previews: some View {
    Text("Stuff")
      .tooltip("Tooltip stuff")
  }
}
