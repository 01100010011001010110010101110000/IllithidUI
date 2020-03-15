//
//  DefaultBrowser.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 2/26/20.
//  Copyright © 2020 Tyler Gregory. All rights reserved.
//

import Cocoa
import Foundation

class Browser: Codable, Identifiable, Comparable, Hashable {
  static func == (lhs: Browser, rhs: Browser) -> Bool {
    lhs.bundle == rhs.bundle
  }

  static func < (lhs: Browser, rhs: Browser) -> Bool {
    lhs.bundle.bundleURL.absoluteString < rhs.bundle.bundleURL.absoluteString
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bundle.bundleURL)
  }

  init?(bundleId: String) {
    guard let bundle = Bundle(identifier: bundleId) else { return nil }
    self.bundle = bundle
  }

  init(bundle: Bundle) {
    self.bundle = bundle
  }

  let bundle: Bundle

  static let inApp: Browser = .init(bundle: Bundle.main)

  /// The default browser at application startup
  static var `default`: Browser? {
    guard let bundleUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://reddit.com")!) else { return nil }
    guard let bundle = Bundle(url: bundleUrl) else { return nil }
    
    return Browser(bundle: bundle)
  }

  static var installed: Set<Browser> {
    // Get all application Bundle URLs that can handle https:// URL schemes
    let array = LSCopyApplicationURLsForURL(NSURL(string: "https://")!, .all)!.takeRetainedValue()
    // Get all application Bundle IDs that can handle html files
    let contentArray = LSCopyAllRoleHandlersForContentType(NSString("public.html"), .viewer)?.takeRetainedValue()
    let bundleUrls = array as! [URL]
    let contentBundleIds = contentArray as! [String]
    var result = bundleUrls
      .compactMap { Bundle(url: $0) }
      .filter { contentBundleIds.contains($0.bundleIdentifier ?? "") }
      .compactMap { Browser(bundle: $0) }
    result.append(Browser(bundle: Bundle.main))

    return Set(result)
  }

  func icon() -> NSImage? {
    bundle.icon()
  }

  var id: String {
    bundle.bundleURL.absoluteString
  }

  var displayName: String? {
    bundle.displayName
  }

  enum CodingKeys: CodingKey {
    case bundleUrl
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(bundle.bundleURL, forKey: .bundleUrl)
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let bundleUrl = try container.decode(URL.self, forKey: .bundleUrl)
    bundle = Bundle(url: bundleUrl)!
  }
}

extension Bundle {
  func icon() -> NSImage? {
    guard let identifier = bundleIdentifier,
      let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: identifier) else { return nil }
    return NSWorkspace.shared.icon(forFile: path)
  }

  var displayName: String? {
      return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String
  }
}
