//
// PostClassicRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/10/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostClassicRowView: View {
  let post: Post

  private var previewImage: String {
    switch post.postHint {
    case .image:
      return "photo.fill"
    case .hostedVideo, .richVideo:
      return "video.fill"
    default:
      return "link"
    }
  }

  private var thumbnailPlaceholder: some View {
    ZStack(alignment: .center) {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .foregroundColor(Color(.darkGray))
      Image(systemName: previewImage)
        .foregroundColor(.blue)
    }
    .frame(width: 90, height: 60)
  }

  var body: some View {
    NavigationLink(
      destination: CommentsView(post: post),
      label: {
        HStack {
          VStack {
            Image(systemName: "arrow.up")
            Text(String(post.ups.postAbbreviation()))
              .foregroundColor(.orange)
            Image(systemName: "arrow.down")
          }
          // Hack to deal with different length upvote count text
          .frame(minWidth: 36)
          if let thumbnailUrl = post.thumbnail {
            WebImage(url: thumbnailUrl)
              .placeholder {
                thumbnailPlaceholder
              }
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 90, height: 60)
              .clipShape(RoundedRectangle(cornerRadius: 8))
          } else {
            thumbnailPlaceholder
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(post.title)
              .fontWeight(.bold)
              .font(.headline)
            HStack {
              Text(post.subredditNamePrefixed)
              Text("Posted by ")
                + Text(post.author)
            }
          }
          Spacer()
        }
        .padding([.top, .bottom], 10)
        .padding(.trailing, 5)
      }
    )
    .frame(width: 400)
  }
}

// struct PostClassicRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostClassicRowView()
//    }
// }
