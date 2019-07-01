//
//  CommentData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/21/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

class CommentData: BindableObject {
  let didChange = PassthroughSubject<CommentData, Never>()

  var comments: [Comment] = [] {
    didSet {
      didChange.send(self)
    }
  }
}
