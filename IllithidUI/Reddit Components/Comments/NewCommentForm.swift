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

import Alamofire
import Illithid

// MARK: - NewCommentForm

struct NewCommentForm<T: Replyable>: View {
  // MARK: Lifecycle

  init(replyTo: T) {
    parentFullname = replyTo.name
  }

  // MARK: Internal

  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    VStack {
      Text("comments.new.heading")
        .font(.title)
        .padding()

      HStack(alignment: .top) {
        TextEditor(text: $commentBody)
          .border(Color(.darkGray))
          .frame(idealWidth: 800, idealHeight: 900)
          .font(.system(size: 18))
        Divider()
        VStack(alignment: .leading) {
          Markdown(mdString: commentBody)
        }
        .frame(minWidth: 200, idealWidth: 800, idealHeight: 900)
      }
      .padding(.horizontal)

      HStack {
        Button(role: .cancel, action: {
          withAnimation {
            presentationMode.wrappedValue.dismiss()
          }
        }, label: {
          Text("cancel")
        })
        .keyboardShortcut(.cancelAction)
        Spacer()
        AsyncButton(action: {
          await submitter.postComment(to: parentFullname, markdown: commentBody)
        }, label: {
          HStack {
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
            Text("comments.submit")
          }
        })
        .keyboardShortcut(.return, modifiers: .command)
      }
      .padding()
      .onReceive(submitter.$result) { result in
        if case .success = result {
          Task {
            try await Task.sleep(nanoseconds: UInt64(dismissalDelay * pow(10, 9)))
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }

  // MARK: Private

  private let parentFullname: Fullname
  private let dismissalDelay: Double = 0.5
  @State private var commentBody: String = ""
  @StateObject private var submitter = CommentSubmitter()
}

// MARK: - CommentSubmitter

@MainActor
private class CommentSubmitter: ObservableObject {
  // MARK: Internal

  @Published var posting: Bool = false
  @Published var result: Result<Comment, AFError>? = nil

  func postComment<T: Replyable>(to replyable: T, markdown: String) async {
    guard !posting else { return }

    posting = true
    submissionTask = replyable.reply(markdown: markdown, automaticallyCancelling: true)
    result = await submissionTask?.result
    posting = false
  }

  func postComment(to parent: Fullname, markdown: String) async {
    guard !posting else { return }

    posting = true
    submissionTask = illithid.postComment(replyingTo: parent, markdown: markdown, automaticallyCanceling: true)
    result = await submissionTask?.result
    posting = false
  }

  // MARK: Private

  private let illithid: Illithid = .shared
  private var submissionTask: DataTask<Comment>?
}
