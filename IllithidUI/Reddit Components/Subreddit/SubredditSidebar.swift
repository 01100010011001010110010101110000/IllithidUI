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

import Illithid
import SDWebImageSwiftUI

// MARK: - SidebarView

struct SubredditSidebar: View {
  // MARK: Lifecycle

  init(subreddit: Subreddit) {
    self.subreddit = subreddit
    _subscribed = .init(initialValue: subreddit.userIsSubscriber ?? false)
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData

  let subreddit: Subreddit

  var body: some View {
    VStack {
      HStack {
        if let headerImageUrl = subreddit.iconImg {
          WebImage(url: headerImageUrl, context: [.imageTransformer: iconResizer])
        }
        Text(subreddit.displayName)
          .font(.largeTitle)
          .fixedSize()
      }

      Divider()

      HStack {
        Spacer()

        IllithidButton(label: {
          Image(systemName: "newspaper.fill")
            .font(.title)
            .foregroundColor(subscribed ? .blue : .white)
        }, mouseUp: {
          if subscribed {
            subreddit.unsubscribe { result in
              if case Result.success = result {
                subscribed = false
                informationBarData.loadSubscriptions()
              }
            }
          } else {
            subreddit.subscribe { result in
              if case Result.success = result {
                subscribed = true
                informationBarData.loadSubscriptions()
              }
            }
          }
        })
          .help("Subscribe")

        IllithidButton(label: {
          Image(systemName: "a.book.closed")
            .font(.title)
            .foregroundColor(.white)
        }, mouseUp: {
          WindowManager.shared.showWindow(withId: "\(subreddit.name)/wiki",
                                          title: "\(subreddit.displayName) Wiki") {
            WikiPagesView(wikiData: .init(subreddit: subreddit))
          }
        })
          .help("Show Wiki")

        Spacer()
      }

      Divider()

      ScrollView {
        if let description = subreddit.attributedDescription {
          VStack(alignment: .leading) {
            AttributedText(attributed: description)
              .padding()
          }
          .padding()
        } else {
          Text("No sidebar text found")
            .padding()
        }
      }
    }
  }

  // MARK: Private

  @State private var subscribed: Bool = false

  private var iconResizer: SDImageResizingTransformer {
    SDImageResizingTransformer(size: CGSize(width: 64, height: 64), scaleMode: .aspectFit)
  }
}
