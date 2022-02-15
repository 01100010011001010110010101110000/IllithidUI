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

import Markdown
import SwiftPress

struct Markdown: View {
  // MARK: Lifecycle

  init(mdString: String) {
    self.mdString = mdString
    document = Document(parsing: mdString)
    _model = .init(wrappedValue: Model())
  }

  // MARK: Internal

  let mdString: String

  @ViewBuilder var body: some View {
    model.render(document)
  }

  // MARK: Private

  private class Model: ObservableObject {
    // MARK: Internal

    func render(_ node: Markup) -> AnyView {
      defer { renderer = SwiftPress() }
      return renderer.visit(node)
    }

    // MARK: Private

    private var renderer = SwiftPress()
  }

  private var document: Document

  @StateObject private var model: Model
}
