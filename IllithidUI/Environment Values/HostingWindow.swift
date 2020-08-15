//
// HostingWindow.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

@dynamicMemberLookup
final class Weak<Value: AnyObject> {
  private weak var value: Value?

  init(_ value: Value?) {
    self.value = value
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T? {
    value?[keyPath: keyPath]
  }
}

struct HostingWindowKey: EnvironmentKey {
  #if canImport(UIKit)
    typealias Value = Weak<UIWindow>
  #elseif canImport(AppKit)
    typealias Value = Weak<NSWindow>
  #else
    #error("Unsupported platform")
  #endif

  static let defaultValue: Value = .init(nil)
}

extension EnvironmentValues {
  var hostingWindow: HostingWindowKey.Value {
    get {
      self[HostingWindowKey.self]
    }
    set {
      self[HostingWindowKey.self] = newValue
    }
  }
}
