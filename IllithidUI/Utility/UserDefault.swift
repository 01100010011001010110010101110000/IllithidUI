//
// UserDefault.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Foundation

@propertyWrapper
struct UserDefault<T: Codable> {
  private let key: String
  private let `default`: T

  init(key: String, default: T) {
    self.key = key
    self.default = `default`
  }

  var wrappedValue: T {
    get {
      guard let data = UserDefaults.standard.data(forKey: key) else { return `default` }
      let value = try? JSONDecoder().decode(T.self, from: data)
      return value ?? `default`
    }
    set {
      let data = try? JSONEncoder().encode(newValue)
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}
