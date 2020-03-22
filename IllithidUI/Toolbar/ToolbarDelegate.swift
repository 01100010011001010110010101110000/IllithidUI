//
// ToolbarDelegate.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Cocoa

extension NSToolbarItem.Identifier {
  static let illithidSearchBar = Self("illithid.reddit.search.bar")
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
    [.illithidSearchBar]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }
}
