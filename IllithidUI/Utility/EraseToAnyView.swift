//
//  EraseToAnyView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

extension View {
  func eraseToAnyView() -> AnyView {
    AnyView(self)
  }
}
