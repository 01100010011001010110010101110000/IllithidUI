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

import Combine
import Foundation
import SwiftUI

import Illithid

// MARK: - NewCommentForm

struct NewCommentForm: View {
  // MARK: Lifecycle

  init(isPresented: Binding<Bool>, comment: Comment) {
    _isPresented = isPresented
    parentFullname = comment.name
  }

  init(isPresented: Binding<Bool>, post: Post) {
    _isPresented = isPresented
    parentFullname = post.name
  }

  // MARK: Internal

  @Binding var isPresented: Bool

  var body: some View {
    VStack {
      Text("comments.new.heading")
        .font(.title)
        .padding()

      TextEditor(text: $commentBody)
        .border(Color.gray)
        .padding(.horizontal)
        .frame(width: 1600, height: 900)
        .font(.system(size: 18))

      HStack {
        Button(action: {
          withAnimation {
            isPresented = false
          }
        }, label: {
          Text("cancel")
        })
          .keyboardShortcut(.cancelAction)
        Spacer()
        Button(action: {
          submitter.postComment(to: parentFullname, body: commentBody)
        }, label: {
          HStack {
            Text("comments.submit")
            if submitter.posting {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(0.5, anchor: .center)
            } else if case .success = submitter.result {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            } else if case .failure = submitter.result {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
            }
          }
        })
          .keyboardShortcut(.return, modifiers: .command)
      }
      .padding()
      .onReceive(submitter.$result) { result in
        switch result {
        case .success:
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
          }
        default:
          break
        }
      }
    }
  }

  // MARK: Private

  private let parentFullname: Fullname
  @State private var commentBody: String = ""
  @StateObject private var submitter = CommentSubmitter()
}

// MARK: - CommentSubmitter

private class CommentSubmitter: ObservableObject {
  // MARK: Internal

  @Published var posting: Bool = false
  @Published var result: Result<Comment, Error>? = nil

  func postComment(to parent: Fullname, body: String) {
    posting = true
    cancelToken = illithid.postComment(replyingTo: parent, body: body)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { [weak self] completion in
        guard let self = self else { return }
        switch completion {
        case let .failure(error):
          self.illithid.logger.errorMessage("Error posting new comment: \(error)")
          self.posting = false
          self.result = .failure(error)
        case .finished:
          self.illithid.logger.debugMessage("Finished posting new comment")
          self.posting = false
        }
      }, receiveValue: { createdComment in
        self.illithid.logger.debugMessage("Received new comment back")
        self.posting = false
        self.result = .success(createdComment)
      })
  }

  // MARK: Private

  private let illithid: Illithid = .shared
  private var cancelToken: AnyCancellable?
}
