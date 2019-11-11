//
//  Tooltips.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 10/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

public extension View {
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
