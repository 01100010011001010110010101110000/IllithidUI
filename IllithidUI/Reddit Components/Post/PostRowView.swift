// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI

import Alamofire
import Illithid
import SDWebImageSwiftUI

// MARK: - PostRowView

struct PostRowView: View {
  // MARK: Lifecycle

  init(post: Post, selection: Binding<Post.ID?>) {
    self.post = post
    _selection = selection
    _actionModel = .init(wrappedValue: .init(post))
    _visitModel = .init(wrappedValue: .init(post: post))
  }

  // MARK: Internal

  @Environment(\.postStyle) var postStyle
  @Environment(\.navigationStyle) var navigationStyle

  let post: Post
  @Binding var selection: Post.ID?

  var body: some View {
    VStack {
      HStack {
        switch navigationStyle {
        case .linear:
          NavigationLink {
            CommentsView(post: post)
              .environmentObject(actionModel)
              .environmentObject(visitModel)
          } label: {
            rowView
          }
        case .multiColumn:
          rowView
            .onTapGesture(count: 2) {
              // Matches the behavior of double clicking on a NavigationLink
              WindowManager.shared.showWindow {
                CommentsView(post: post)
                  .environmentObject(actionModel)
                  .environmentObject(visitModel)
              }
            }
        }
        Spacer()
      }
      .brightness(visitModel.visited ? -0.2 : 0.0)
      Divider()
    }
    .contextMenu {
      PostContextMenu(post: post, presentReplyForm: $presentReplyForm, model: actionModel)
    }
    .sheet(isPresented: $presentReplyForm) {
      NewCommentForm(replyTo: post)
    }
    .environmentObject(actionModel)
  }

  // MARK: Private

  @State private var presentReplyForm = false
  @StateObject private var actionModel: CommonActionModel<Post>
  @StateObject private var visitModel: PostVisitModel

  private let windowManager: WindowManager = .shared

  @ViewBuilder private var rowView: some View {
    switch postStyle {
    case .large:
      DetailedPostRowView(post: post, presentReplyForm: $presentReplyForm, selection: $selection)
    case .classic, .compact:
      ClassicPostRowView(post: post, selection: $selection)
    }
  }
}

// MARK: - PostVisitModel

@MainActor
final class PostVisitModel: ObservableObject {
  // MARK: Lifecycle

  init(post: Post) {
    visited = post.visited
    self.post = post
  }

  // MARK: Internal

  @Published var visited: Bool

  func visit() async {
    guard !visited,
          visitingTask == nil,
          Illithid.shared.accountManager.currentAccount?.hasSubscribedToPremium ?? false else { return }

    visitingTask = post.visit(automaticallyCancelling: true)
    visited = (try? await visitingTask?.value) != nil
    visitingTask = nil
  }

  // MARK: Private

  private let post: Post
  private var visitingTask: DataTask<Data>?
}

// MARK: - DetailedPostRowView

private struct DetailedPostRowView: View {
  // MARK: Internal

  let post: Post

  @Binding var presentReplyForm: Bool
  @Binding var selection: Post.ID?

  var body: some View {
    HStack(spacing: 10) {
      PostActionBar(post: post, presentReplyForm: $presentReplyForm)
      Divider()
      DetailedPostView(post: post)
    }
    .padding(.vertical, 10)
  }

  // MARK: Private

  @EnvironmentObject private var model: CommonActionModel<Post>
}

// MARK: - ClassicPostRowView

private struct ClassicPostRowView: View {
  // MARK: Internal

  let post: Post

  @Binding var selection: Post.ID?
  @EnvironmentObject var model: CommonActionModel<Post>

  var body: some View {
    HStack(alignment: .top) {
      VStack {
        // TODO: Implement voting logic
        Image(systemName: "arrow.up")
        Image(systemName: "arrow.down")
      }

      if let thumbnailUrl = post.thumbnail {
        WebImage(url: thumbnailUrl)
          .placeholder {
            thumbnailPlaceholder
          }
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 96, height: 72)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      } else {
        thumbnailPlaceholder
      }

      VStack(alignment: .leading, spacing: 10) {
        PostRowView.TitleView(post: post)
        PostRowView.PostMetadataBar(post: post)
      }
      .padding(.leading, 10)
    }
    .padding(.vertical, 10)
    .padding(.trailing, 5)
  }

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared
  private let windowManager: WindowManager = .shared

  private var previewImage: String {
    switch post.previewGuess {
    case .text:
      return "text.bubble.fill"
    case .gallery:
      return "photo.fill.on.rectangle.fill"
    case .image:
      return "photo.fill"
    case .gfycat, .gif, .redgifs, .video, .youtube:
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
    .frame(width: 96, height: 72)
  }
}

// MARK: - PostActionBar

struct PostActionBar: View {
  // MARK: Internal

  let post: Post

  @Binding var presentReplyForm: Bool

  var body: some View {
    VStack {
      IllithidButton(action: {
        Task {
          try? await model.upvote()
        }
      }, label: {
        Image(systemName: "arrow.up")
          .foregroundColor(model.vote == .up ? .orange : .white)
      })
      IllithidButton(action: {
        Task {
          try? await model.downvote()
        }
      }, label: {
        Image(systemName: "arrow.down")
          .foregroundColor(model.vote == .down ? .purple : .white)
      })
      IllithidButton(action: {
        Task {
          try? await model.toggleSaved()
        }
      }, label: {
        Image(systemName: "bookmark.fill")
          .foregroundColor(model.saved ? .green : .white)
      })
      IllithidButton(action: {
        withAnimation {
          presentReplyForm = true
        }
      }, label: {
        Image(systemName: "arrowshape.turn.up.backward.fill")
      })

      Spacer()

      IllithidButton(action: {}, label: {
        Image(systemName: "eye.slash")
      })
      IllithidButton(action: {}, label: {
        Image(systemName: "flag")
      })
    }
    .font(.title2)
  }

  // MARK: Private

  @EnvironmentObject private var model: CommonActionModel<Post>
}

// MARK: - PostRowView_Previews

// struct PostRowView_Previews: PreviewProvider {
//  static var previews: some View {
//    let decoder = JSONDecoder()
//    decoder.dateDecodingStrategy = .secondsSince1970
//
//    let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
//    let data = try! Data(contentsOf: singlePostURL)
//    let post = try! decoder.decode(Post.self, from: data)
//
//    return PostRowView(post: post, selection: .constant(nil))
//  }
// }
