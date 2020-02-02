//
// CommentRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct CommentRowView: View {
  let comment: Comment
  let depth: Int

  init(comment: Comment) {
    self.comment = comment
    depth = comment.depth ?? 0
  }

  var body: some View {
    HStack {
      if depth > 0 {
        RoundedRectangle(cornerRadius: 1.5)
          .foregroundColor(Color(hue: 1.0 / Double(depth), saturation: 1.0, brightness: 1.0))
          .frame(width: 3)
      }

      VStack(alignment: .leading, spacing: 0) {
        Text(comment.author)
          .font(.subheadline)
          .fontWeight(.heavy)

        Text(comment.body)
          .font(.body)
          .padding()

        Divider()
          .opacity(1.0)
      }
    }.padding(.leading, 20 * CGFloat(integerLiteral: depth))
  }
}

// #if DEBUG
// struct CommentRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        CommentRowView()
//    }
// }
// #endif
