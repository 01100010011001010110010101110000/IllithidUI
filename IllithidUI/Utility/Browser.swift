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
import Foundation

// MARK: - Browser

/// Represents an installed browser
class Browser: Codable, Identifiable, Comparable, Hashable {
  // MARK: Lifecycle

  init?(bundleId: String) {
    guard let bundle = Bundle(identifier: bundleId) else { return nil }
    self.bundle = bundle
  }

  init(bundle: Bundle) {
    self.bundle = bundle
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let bundleUrl = try container.decode(URL.self, forKey: .bundleUrl)
    bundle = Bundle(url: bundleUrl) ?? Bundle()
  }

  // MARK: Public

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bundle.bundleURL)
  }

  // MARK: Internal

  enum CodingKeys: CodingKey {
    case bundleUrl
  }

  /// Represents the in app browser
  static let inApp: Browser = .init(bundle: Bundle.main)

  /// The default browser at application startup
  static var `default`: Browser? {
    guard let bundleUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://reddit.com")!) else { return nil }
    guard let bundle = Bundle(url: bundleUrl) else { return nil }

    return Browser(bundle: bundle)
  }

  /// The set of installed browsers
  /// - Note: This attempts to filter installed apps to only actual browsers by taking the difference of applications that handle https links, and those which handle html files
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

  let bundle: Bundle

  var id: String {
    bundle.bundleURL.absoluteString
  }

  var displayName: String? {
    bundle.displayName
  }

  static func == (lhs: Browser, rhs: Browser) -> Bool {
    lhs.bundle == rhs.bundle
  }

  static func < (lhs: Browser, rhs: Browser) -> Bool {
    lhs.bundle.bundleURL.absoluteString < rhs.bundle.bundleURL.absoluteString
  }

  func icon() -> NSImage? {
    bundle.icon()
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(bundle.bundleURL, forKey: .bundleUrl)
  }
}

extension Bundle {
  func icon() -> NSImage? {
    guard let identifier = bundleIdentifier,
          let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else { return nil }
    return NSWorkspace.shared.icon(forFile: url.path)
  }

  var displayName: String? {
    object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
      object(forInfoDictionaryKey: "CFBundleName") as? String
  }
}
