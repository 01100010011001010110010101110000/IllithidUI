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

import Illithid
import SDWebImageSwiftUI

// MARK: - PreferencesView

struct PreferencesView: View {
  // MARK: Internal

  @ObservedObject var accountManager: AccountManager

  var body: some View {
    VStack {
      switch preferencePage {
      case .general:
        GeneralPreferences()
          .navigationTitle("General")
      case .navigation:
        NavigationPreferences()
          .navigationTitle("Navigation")
      case .accounts:
        AccountsPreferences(accountManager: accountManager)
          .navigationTitle("Accounts")
      case .advanced:
        AdvancedPreferences()
          .navigationTitle("Advanced")
      }
    }
    .padding(.top, 20)
    .frame(minWidth: 550, maxWidth: 550, maxHeight: 800)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .general)
      }

      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .navigation)
      }

      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .accounts)
      }

      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .advanced)
      }
    }
  }

  // MARK: Private

  @State private var preferencePage: PreferencePage = .general
}

// MARK: - PreferencesToolbarItemView

private struct PreferencesToolbarItemView: View {
  @Binding var selection: PreferencesView.PreferencePage
  @State private var hovering: Bool = false

  let page: PreferencesView.PreferencePage

  var iconColor: Color {
    if selection == page, hovering { return Color(.cyan) }
    if selection == page { return .blue }
    if hovering { return .white }
    return .gray
  }

  var body: some View {
    VStack(spacing: 1) {
      Image(systemName: page.iconName)
        .foregroundColor(iconColor)
        .font(.title2)
        .onHover { hovering in
          self.hovering = hovering
        }

      Text(page.rawValue.capitalized)
        .font(.body)
    }
    .padding(4)
    .onTapGesture {
      selection = page
    }
    .overlay(RoundedRectangle(cornerRadius: 8).foregroundColor(page == selection ? .white : .clear).opacity(0.2))
  }
}

extension PreferencesView {
  enum PreferencePage: String, Identifiable, CaseIterable {
    case general
    case navigation
    case accounts
    case advanced

    // MARK: Internal

    var id: String {
      rawValue
    }

    var iconName: String {
      switch self {
      case .general:
        return "gearshape"
      case .navigation:
        return "map"
      case .accounts:
        return "person.crop.circle"
      case .advanced:
        return "gearshape.2"
      }
    }
  }
}

// MARK: - GeneralPreferences

private struct GeneralPreferences: View {
  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    VStack(alignment: .leading) {
      GroupBox(label: Text("Content").font(.headline)) {
        VStack(alignment: .leading) {
          Toggle(isOn: $preferences.hideNsfw) {
            Text("Hide NSFW content")
          }

          Toggle(isOn: $preferences.blurNsfw) {
            Text("Blur NSFW content")
          }

          Toggle(isOn: $preferences.openLinksInForeground) {
            Text("Open links in foreground")
          }

          Picker(selection: $preferences.previewSize, label: Text("Preview Size: ")) {
            ForEach(PreferencesData.PreviewSize.allCases) { size in
              Text(size.rawValue.capitalized)
                .tag(size)
            }
          }
          .frame(width: 200)

          Picker(selection: $preferences.browser, label: Text("Open links with: ")) {
            ForEach(Browser.installed.sorted().filter { $0.displayName != nil }) { browser in
              HStack {
                if let icon = browser.icon()?.resized(to: NSSize(width: 16, height: 16)) {
                  Image(nsImage: icon)
                }
                Text(browser.displayName!)
              }
              .tag(browser)
            }
          }
          .frame(width: 250, alignment: .leading)
        }
      }

      GroupBox(label: Text("Playback").font(.headline)) {
        VStack(alignment: .leading) {
          Toggle(isOn: $preferences.muteAudio) {
            Text("Mute audio content")
          }
          Toggle(isOn: $preferences.autoPlayGifs) {
            Text("Auto play GIFs")
          }
        }
      }
      Spacer()
    }
  }
}

// MARK: - NavigationPreferences

private struct NavigationPreferences: View {
  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    VStack(alignment: .leading) {
      GroupBox(label: Text("Navigation Layout").font(.headline)) {
        VStack(alignment: .leading) {
          Picker(selection: $preferences.navigationStyle, label: Text("Layout: ")) {
            ForEach(NavigationStyle.allCases) { style in
              HStack {
                Text(style.rawValue.capitalized)
              }
              .tag(style)
            }
          }
          .frame(width: 400)
        }
      }
      Spacer()
    }
  }
}

func openLink(_ link: URL) {
  let preferences: PreferencesData = .shared

  let toOpen = preferences.browser.bundle == Bundle.main ? URL(string: "illithid://open-url?url=\(link.absoluteString)")! : link

  NSWorkspace.shared.open([toOpen],
                          withApplicationAt: preferences.browser.bundle.bundleURL,
                          configuration: .linkConfiguration)
}

// MARK: - AccountsPreferences

private struct AccountsPreferences: View {
  @ObservedObject var accountManager: AccountManager

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      List {
        ForEach(accountManager.accounts) { account in
          HStack {
            if let currentAccount = accountManager.currentAccount, currentAccount.id == account.id {
              Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            }
            if accountManager.isAuthenticated(account) {
              Text(account.name)
                .onTapGesture { accountManager.setAccount(account) }
            } else {
              Text(account.name)
                .foregroundColor(.red)
              Spacer()
              Button(action: { accountManager.reauthenticate(account: account, anchor: (NSApp.keyWindow ?? NSApp.mainWindow)!) }) {
                Text("Renew Credentials")
              }
            }
          }
        }
        .onDelete(perform: { accountManager.removeAccounts(indexSet: $0) })
        .padding()
      }
      HStack {
        Button(action: {
          accountManager.addAccount(anchor: NSApp.keyWindow!)
        }) { Text("Add account") }
        Spacer()
        Button(action: {
          accountManager.removeAll()
        }) {
          Text("Remove all accounts")
        }
        .disabled(accountManager.accounts.isEmpty)
      }
      .padding()
    }
  }
}

// MARK: - AdvancedPreferences

private struct AdvancedPreferences: View {
  // MARK: Internal

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Text("Cache size on disk: \(model.diskUsage)")
        Button(action: {
          model.clearImageCache()
        }, label: {
          Text("Clear image cache")
        })
      }
      Spacer()
    }
    .onAppear {
      model.calculateCacheDiskUsage()
    }
  }

  // MARK: Private

  @MainActor
  private final class ViewModel: ObservableObject {
    @Published var diskUsageBytes: UInt = 0

    var diskUsage: String {
      byteFormatter.string(fromByteCount: Int64(diskUsageBytes))
    }

    func clearImageCache() {
      SDWebImageManager.defaultImageCache?.clear(with: .all, completion: nil)
      calculateCacheDiskUsage()
    }

    func calculateCacheDiskUsage() {
      guard let cacheManager = SDWebImageManager.defaultImageCache as? SDImageCachesManager else {
        diskUsageBytes = 0
        return
      }
      Task {
        let calcTask = Task.detached {
          cacheManager.caches?
            .compactMap { $0 as? SDImageCache }
            .reduce(0, { $0 + $1.totalDiskSize() }) ?? 0
        }
        self.diskUsageBytes = await calcTask.value
      }
    }
  }

  private static let byteFormatter: ByteCountFormatter = {
    var formatter = ByteCountFormatter()
    formatter.zeroPadsFractionDigits = true
    return formatter
  }()

  @ObservedObject private var preferences: PreferencesData = .shared
  @StateObject private var model = Self.ViewModel()
}

// MARK: - PreferencesData

final class PreferencesData: ObservableObject, Codable {
  // MARK: Lifecycle

  private init() {
    hideNsfw = false
    blurNsfw = true
    muteAudio = true
    autoPlayGifs = false
    openLinksInForeground = true
    browser = .inApp
    previewSize = .small
    navigationStyle = NavigationStyleKey.defaultValue
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    hideNsfw = try (container.decodeIfPresent(Bool.self, forKey: .hideNsfw) ?? false)
    blurNsfw = try (container.decodeIfPresent(Bool.self, forKey: .blurNsfw) ?? true)
    muteAudio = try (container.decodeIfPresent(Bool.self, forKey: .muteAudio) ?? true)
    autoPlayGifs = try (container.decodeIfPresent(Bool.self, forKey: .autoPlayGifs) ?? false)
    browser = try (container.decodeIfPresent(Browser.self, forKey: .browser) ?? .inApp)
    openLinksInForeground = try (container.decodeIfPresent(Bool.self, forKey: .openLinksInForeground) ?? true)
    previewSize = try (container.decodeIfPresent(PreviewSize.self, forKey: .previewSize) ?? .small)
    navigationStyle = try (container.decodeIfPresent(NavigationStyle.self, forKey: .navigationStyle) ?? NavigationStyleKey.defaultValue)
  }

  // MARK: Internal

  enum CodingKeys: CodingKey {
    case hideNsfw
    case blurNsfw
    case muteAudio
    case autoPlayGifs
    /// Which `Browser` to use for Links
    case browser
    case openLinksInForeground
    case previewSize
    case navigationStyle
  }

  static let shared: PreferencesData = {
    if let data = defaults.data(forKey: "preferences"),
       let value = try? JSONDecoder().decode(PreferencesData.self, from: data) {
      return value
    } else {
      return .init()
    }
  }()

  @Published fileprivate(set) var hideNsfw: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var blurNsfw: Bool {
    didSet {
      updateDefaults()
    }
  }

  // MARK: Playback

  @Published fileprivate(set) var muteAudio: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var autoPlayGifs: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var openLinksInForeground: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var browser: Browser {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var previewSize: PreviewSize {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var navigationStyle: NavigationStyle {
    didSet {
      updateDefaults()
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(hideNsfw, forKey: .hideNsfw)
    try container.encode(blurNsfw, forKey: .blurNsfw)
    try container.encode(muteAudio, forKey: .muteAudio)
    try container.encode(autoPlayGifs, forKey: .autoPlayGifs)
    try container.encode(browser, forKey: .browser)
    try container.encode(openLinksInForeground, forKey: .openLinksInForeground)
    try container.encode(previewSize, forKey: .previewSize)
    try container.encode(navigationStyle, forKey: .navigationStyle)
  }

  // MARK: Private

  private static let defaults: UserDefaults = .standard

  private func updateDefaults() {
    guard let data = try? JSONEncoder().encode(self) else {
      // TODO: Error logging
      return
    }

    Self.defaults.set(data, forKey: "preferences")
  }
}

extension PreferencesData {
  enum PreviewSize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    // MARK: Internal

    var id: Self.RawValue {
      rawValue
    }

    var targetSize: CGSize {
      switch self {
      case .small:
        return CGSize(width: 480, height: 360)
      case .medium:
        return CGSize(width: 720, height: 480)
      case .large:
        return CGSize(width: 1280, height: 720)
      }
    }
  }
}

// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
