//
//  CommentsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/19/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct CommentsView: View {
  let post: Post

  var body: some View {
    Text(post.title).frame(width: 600, height: 400)
  }
}

// #if DEBUG
// struct CommentsView_Previews : PreviewProvider {
//    static var previews: some View {
//        CommentsView()
//    }
// }
// #endif
