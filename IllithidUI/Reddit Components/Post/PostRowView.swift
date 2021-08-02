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
  @Environment(\.postStyle) var postStyle

  let post: Post
  @Binding var selection: Post.ID?

  var body: some View {
    switch postStyle {
    case .large:
      DetailedPostRowView(post: post, selection: $selection)
    case .classic, .compact:
      ClassicPostRowView(post: post, selection: $selection)
    }
  }
}

// MARK: - DetailedPostRowView

struct DetailedPostRowView: View {
  // MARK: Lifecycle

  init(post: Post, selection: Binding<Post.ID?> = .constant(nil)) {
    self.post = post
    _selection = selection
    _voteState = .init(initialValue: VoteDirection(from: post))
  }

  // MARK: Internal

  @Binding var selection: Post.ID?

  let post: Post

  var body: some View {
    GroupBox {
      HStack {
        PostActionBar(post: post, presentReplyForm: $presentReplyForm, vote: $voteState)
        Divider()
        DetailedPostView(post: post, vote: $voteState)

        Spacer()

        Group {
          if selection == post.id {
            commentsButton
              .keyboardShortcut(.defaultAction)
          } else {
            commentsButton
          }
        }
        .padding(10)
      }
    }
    .sheet(isPresented: $presentReplyForm) {
      NewCommentForm(isPresented: $presentReplyForm, post: post)
    }
    .contextMenu {
      Button(action: {
        showComments(for: post)
      }, label: {
        Text("Show comments…")
      })
      Button(action: {
        withAnimation {
          presentReplyForm = true
        }
      }, label: {
        Text("Reply…")
      })
      Menu("Open in Browser…") {
        Button(action: {
          openLink(post.postUrl)
        }, label: {
          Text("Post…")
        })
        Button(action: {
          openLink(post.contentUrl)
        }, label: {
          Text("Post content…")
        })
      }
      Divider()
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(post.postUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy post URL")
      })
      Button(action: {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(post.contentUrl.absoluteString, forType: .string)
      }, label: {
        Text("Copy content URL")
      })
      Divider()
      #if DEBUG
        Button(action: {
          showDebugWindow(for: post)
        }) {
          Text(verbatim: "Show debug panel…")
        }
      #endif
    }
  }

  func showComments(for post: Post) {
    windowManager.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }

  func showDebugWindow(for post: Post) {
    windowManager.showMainWindowTab(withId: "\(post.name)_debug", title: "\(post.title) - Debug View") {
      PostDebugView(post: post)
    }
  }

  // MARK: Private

  private let windowManager: WindowManager = .shared

  @State private var voteState: VoteDirection
  @State private var presentReplyForm: Bool = false

  private var commentsButton: some View {
    Button(action: {
      showComments(for: post)
    }, label: {
      Image(systemName: "chevron.right")
    })
      .opacity(0.0)
  }
}

// MARK: - ClassicPostRowView

struct ClassicPostRowView: View {
  // MARK: Lifecycle

  init(post: Post, selection: Binding<Post.ID?> = .constant(nil)) {
    self.post = post
    _selection = selection
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData
  @Binding var selection: Post.ID?

  let post: Post

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
        Group {
          if selection == post.id {
            commentsButton
              .keyboardShortcut(.defaultAction)
          } else {
            commentsButton
          }
        }
        .padding(10)
      }
      .padding([.top, .bottom], 10)
      .padding(.trailing, 5)
    }
    .frame(maxWidth: .infinity)
  }

  func showComments(for post: Post) {
    windowManager.showMainWindowTab(withId: post.name, title: post.title) {
      CommentsView(post: post)
    }
  }

  // MARK: Private

  @ObservedObject private var moderators: ModeratorData = .shared
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

  private var commentsButton: some View {
    Button(action: {
      showComments(for: post)
    }, label: {
      Image(systemName: "chevron.right")
    })
  }
}

// MARK: - PostActionBar

// TODO: Sync saved and voted state with model
struct PostActionBar: View {
  // MARK: Lifecycle

  init(post: Post, presentReplyForm: Binding<Bool>, vote: Binding<VoteDirection>) {
    self.post = post
    _presentReplyForm = presentReplyForm

    _vote = vote
    _saved = .init(initialValue: post.saved)
  }

  // MARK: Internal

  @Binding var presentReplyForm: Bool

  let post: Post

  @Binding var vote: VoteDirection

  var body: some View {
    VStack {
      IllithidButton(action: {
        if vote == .up {
          post.clearVote { result in
            switch result {
            case .success:
              vote = .clear
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error clearing vote on \(post.title) - \(post.name): \(error)")
            }
          }
        } else {
          post.upvote { result in
            switch result {
            case .success:
              vote = .up
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error upvoting \(post.title) - \(post.name): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "arrow.up")
          .foregroundColor(vote == .up ? .orange : .white)
      })
      IllithidButton(action: {
        if vote == .down {
          post.clearVote { result in
            switch result {
            case .success:
              vote = .clear
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error clearing vote on \(post.title) - \(post.name): \(error)")
            }
          }
        } else {
          post.downvote { result in
            switch result {
            case .success:
              vote = .down
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error downvoting \(post.title) - \(post.name): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "arrow.down")
          .foregroundColor(vote == .down ? .purple : .white)
      })
      IllithidButton(action: {
        if saved {
          post.unsave { result in
            switch result {
            case .success:
              saved = false
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error unsaving \(post.title) - \(post.name): \(error)")
            }
          }
        } else {
          post.save { result in
            switch result {
            case .success:
              saved = true
            case let .failure(error):
              Illithid.shared.logger.errorMessage("Error saving \(post.title) - \(post.name): \(error)")
            }
          }
        }
      }, label: {
        Image(systemName: "bookmark.fill")
          .foregroundColor(saved ? .green : .white)
      })
      IllithidButton(action: {
        presentReplyForm = true
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
    .padding(10)
  }

  // MARK: Private

  @State private var saved: Bool
}

// MARK: - PostRowView_Previews

struct PostRowView_Previews: PreviewProvider {
  static var previews: some View {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970

    let singlePostURL = Bundle.main.url(forResource: "single_post", withExtension: "json")!
    let data = try! Data(contentsOf: singlePostURL)
    let post = try! decoder.decode(Post.self, from: data)

    return PostRowView(post: post, selection: .constant(nil))
  }
}
