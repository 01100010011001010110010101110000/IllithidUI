//
//  Toolbar.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/18/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Cocoa

extension NSToolbarItem.Identifier {
  static let illithidSearchBar = Self.init("illithid.reddit.search.bar")
}

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
    return [.illithidSearchBar]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return toolbarDefaultItemIdentifiers(toolbar)
  }
}
