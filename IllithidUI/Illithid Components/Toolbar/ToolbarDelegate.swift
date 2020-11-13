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

import Cocoa

extension NSToolbarItem.Identifier {
  static let illithidSearchBar = Self("illithid.reddit.search.bar")
}

// MARK: - ToolbarDelegate

class ToolbarDelegate: NSObject, NSToolbarDelegate {
  func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
    let newItem = NSToolbarItemGroup(itemIdentifier: itemIdentifier)

    let textField = NSTextField()
    textField.placeholderString = "Search Reddit"
    textField.heightAnchor.constraint(equalToConstant: 22)
      .isActive = true
    let searchItem = NSToolbarItem(itemIdentifier: .illithidSearchBar)
    searchItem.view = textField

    newItem.subitems = [searchItem]

    return newItem
  }

  func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
    [.illithidSearchBar]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }
}
