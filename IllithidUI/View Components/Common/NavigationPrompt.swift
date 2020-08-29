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

struct NavigationPrompt: View {
  let prompt: String
  var body: some View {
    Text(prompt)
      .font(.largeTitle)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct NavigationPrompt_Previews: PreviewProvider {
  static var previews: some View {
    NavigationPrompt(prompt: "Hello, I am a prompt")
  }
}
