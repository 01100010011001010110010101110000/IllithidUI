//
// ClassicListBody.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/12/20
//

import SwiftUI

import Illithid

struct ClassicListBody: View {
  @Namespace var ns
  let posts: [Post]
  let onLastPost: () -> Void

  @State private var blur: Bool = false
  @State private var selection: Post? = nil

  func openModal(for post: Post) {
    withAnimation(.modal) { selection = post }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = true }
    }
  }

  func closeModal() {
    withAnimation(.modal) { selection = nil }
    DispatchQueue.main.async {
      withAnimation(.blur) { blur = false }
    }
  }

  var body: some View {
    ZStack {
      List {
        ForEach(posts) { post in
          PostClassicRowView(post: post)
            .onTapGesture {
              openModal(for: post)
            }
            .opacity(selection?.id == post.id ? 0.0 : 1.0)
            .onAppear {
              if post == posts.last {
                onLastPost()
              }
            }
        }
      }
      .disabled(selection != nil)
      .blur(radius: blur ? 25 : 0)
      .transition(.opacity)
      .zIndex(1)

      if let post = selection {
        RoundedRectangle(cornerRadius: 8)
          .onMouseGesture(mouseDown: {
            closeModal()
          }, mouseUp: {})
          .foregroundColor(.clear)
          .zIndex(2)

        PostModalView(post: post)
      }
    }
  }
}

private extension Animation {
  static let modal: Animation = .interactiveSpring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.25)
  static let blur: Animation = .linear(duration: 0.25)
}

// struct ClassicListBody_Previews: PreviewProvider {
//    static var previews: some View {
//      ClassicListBody(posts: .constant([]),
//                      postsData: .init(provider: /* TODO Fill in */),
//                      sorter: .init(sort: .best, topInterval: .day)
//      )
//    }
// }
