//
//  PostsData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/9/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

final class PostData: BindableObject {
  let didChange = PassthroughSubject<PostData, Never>()

  var posts: [Post] = [] {
    didSet {
      didChange.send(self)
    }
  }
}
