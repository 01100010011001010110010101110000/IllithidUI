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

struct SubredditSuggestionLabel: View {
  let suggestion: Subreddit

  static let CreatedFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
  }()

  var body: some View {
    GroupBox {
      VStack(alignment: .center) {
        SubredditIcon(subreddit: suggestion)
          .overlay(Circle().stroke(Color.white, lineWidth: 4))
          .shadow(radius: 10)
          .frame(width: 256, height: 256)

        HStack {
          Label("\(suggestion.subscribers?.postAbbreviation() ?? "???")", systemImage: "newspaper.fill")
            .help("\(suggestion.subscribers?.description ?? "???") subscribers")
          Spacer()
          Text(suggestion.displayNamePrefixed)
            .bold()
          Spacer()
          Label("\(suggestion.created, formatter: Self.CreatedFormatter)", systemImage: "calendar.badge.clock")
            .help("Created on \(suggestion.created, formatter: Self.CreatedFormatter)")
        }
        .padding(.vertical, 5)

        HStack {
          Spacer()
          if !suggestion.publicDescription.isEmpty {
            Text(suggestion.publicDescription)
              .lineLimit(3)
              .help(suggestion.publicDescription)
          }
          Spacer()
        }
      }
      .padding(10)
      .frame(height: 380)
    }
  }
}

// struct SubredditSuggestionLabel_Previews: PreviewProvider {
//    static var previews: some View {
//        SubredditSuggestionLabel()
//    }
// }
