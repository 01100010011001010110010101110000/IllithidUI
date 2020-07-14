//
// PostClassicRowView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/10/20
//

import SwiftUI

import Illithid
import SDWebImageSwiftUI

struct PostClassicRowView: View {
  @ObservedObject private var moderators: ModeratorData = .shared
  @EnvironmentObject var informationBarData: InformationBarData

  let post: Post
  private let windowManager: WindowManager = .shared

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

  private var authorColor: Color {
    if post.isAdminPost {
      return .red
    } else if moderators.isModerator(username: post.author, ofSubreddit: post.subreddit) {
      return .green
    } else {
      return .white
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
    GroupBox {
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
            .heightResizable()
          HStack {
            Text(post.subredditNamePrefixed)
              .onTapGesture {
                windowManager.showMainWindowTab(withId: post.subredditId, title: post.subredditNamePrefixed) {
                  SubredditLoader(fullname: post.subredditId)
                    .environmentObject(informationBarData)
                }
              }
            (Text("by ")
              + Text(post.author).usernameStyle(color: authorColor))
              .onTapGesture {
                windowManager.showMainWindowTab(withId: post.author, title: post.author) {
                  AccountView(name: post.author)
                    .environmentObject(informationBarData)
                }
              }
          }
        }
        Spacer()
      }
      .padding([.top, .bottom], 10)
      .padding(.trailing, 5)
    }
    .frame(maxWidth: .infinity)
  }
}

// struct PostClassicRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostClassicRowView()
//    }
// }
