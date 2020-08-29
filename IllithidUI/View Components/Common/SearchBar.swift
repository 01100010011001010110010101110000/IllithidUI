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
import SwiftUI

import Alamofire
import Illithid

struct SearchBar<S: StringProtocol>: View {
  let title: S
  @Binding var text: String
  let onEditingChanged: (Bool) -> Void
  let onCommit: () -> Void

  let disableAutocorrect: Bool

  init(title: S, text: Binding<String>,
       onEditingChanged: @escaping (Bool) -> Void = { _ in },
       onCommit: @escaping () -> Void = {},
       disableAutocorrect: Bool = true) {
    self.title = title
    _text = text
    self.onEditingChanged = onEditingChanged
    self.onCommit = onCommit

    self.disableAutocorrect = disableAutocorrect
  }

  var body: some View {
    VStack(alignment: .leading) {
      TextField(title, text: $text, onEditingChanged: onEditingChanged, onCommit: onCommit)
        .disableAutocorrection(disableAutocorrect)
        .padding(.bottom, 5)
      VStack(alignment: .leading) {
        Text("Lorem")
        Divider()
        Text("Ipsum")
      }
    }
  }
}

protocol Titled {
  var title: String { get }
}

protocol DetailedDescription {
  var detailedDescription: String { get }
}

extension Subreddit: Titled, DetailedDescription {
  var title: String {
    displayName
  }

  var detailedDescription: String {
    publicDescription
  }
}

class SearchBarAutocomplete<T: Titled & DetailedDescription>: ObservableObject {
  @Published var toComplete: String = ""
  @Published var suggestions: [T] = []
  let complete: (String, ([T]) -> Void) -> DataRequest

  var cancelTokens: [AnyCancellable] = []

  init(complete: @escaping (String, ([T]) -> Void) -> DataRequest) {
    self.complete = complete
    let cancelToken = $toComplete
      .filter { $0.count >= 3 }
      .debounce(for: 0.3, scheduler: RunLoop.current)
      .removeDuplicates()
      .sink { [weak self] token in
        guard let self = self else { return }
        _ = complete(token) { [weak self] suggested in
          guard let self = self else { return }
          self.suggestions = suggested
        }
      }
    cancelTokens.append(cancelToken)
  }
}

struct SearchBar_Previews: PreviewProvider {
  @State private static var text: String = ""

  static var previews: some View {
    SearchBar(title: "", text: $text)
  }
}
