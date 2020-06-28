//
// PreferencesView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 6/27/20
//

import SwiftUI

import Illithid

struct PreferencesView: View {
  @ObservedObject var accountManager: AccountManager

  var body: some View {
    TabView {
      GeneralPreferences()
        .tabItem {
          Text("General")
        }
      AccountsPreferences(accountManager: accountManager)
        .tabItem {
          Text("Accounts")
        }
    }
    .padding()
    .frame(minWidth: 300, minHeight: 500)
  }
}

struct GeneralPreferences: View {
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

          Picker(selection: $preferences.browser, label: Text("Open links in: ")) {
            ForEach(Browser.installed.sorted()) { browser in
              HStack {
                if let icon = browser.icon() {
                  Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                }
                Text(browser.displayName!)
              }
              .tag(browser)
            }
          }
          Toggle(isOn: $preferences.openLinksInForeground) {
            Text("Open links in foreground")
          }
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

func openLink(_ link: URL) {
  let preferences: PreferencesData = .shared

  let toOpen = preferences.browser.bundle == Bundle.main ? URL(string: "illithid://open-url?url=\(link.absoluteString)")! : link

  NSWorkspace.shared.open([toOpen],
                          withApplicationAt: preferences.browser.bundle.bundleURL,
                          configuration: .linkConfiguration)
}

struct AccountsPreferences: View {
  @ObservedObject var accountManager: AccountManager

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      List {
        ForEach(accountManager.accounts) { account in
          HStack {
            if self.accountManager.currentAccount == account {
              Image(named: .checkmark)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.green)
            }
            if self.accountManager.isAuthenticated(account) {
              Text(account.name)
                .onTapGesture { self.accountManager.setAccount(account) }
            } else {
              Text(account.name)
                .foregroundColor(.red)
              Spacer()
              Button(action: { self.accountManager.reauthenticate(account: account, anchor: NSApp.keyWindow!) }) {
                Text("Renew Credentials")
              }
            }
          }
          .animation(.spring())
        }
        .onDelete(perform: { self.accountManager.removeAccounts(indexSet: $0) })
        .padding()
      }
      HStack {
        Button(action: {
          self.accountManager.addAccount(anchor: NSApp.keyWindow!)
        }) { Text("Add account") }
        Spacer()
        Button(action: {
          self.accountManager.removeAll()
        }) { Text("Remove all accounts") }
      }
      .padding()
    }
  }
}

final class PreferencesData: ObservableObject, Codable {
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

  enum CodingKeys: CodingKey {
    case hideNsfw
    case blurNsfw
    case muteAudio
    case autoPlayGifs
    /// Which `Browser` to use for Links
    case browser
    case openLinksInForeground
  }

  private init() {
    hideNsfw = false
    blurNsfw = true
    muteAudio = true
    autoPlayGifs = false
    openLinksInForeground = true
    browser = .inApp
  }

  static let shared: PreferencesData = {
    if let data = UserDefaults.standard.data(forKey: "preferences"),
      let value = try? JSONDecoder().decode(PreferencesData.self, from: data) {
      return value
    } else {
      return .init()
    }
  }()

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    hideNsfw = try (container.decodeIfPresent(Bool.self, forKey: .hideNsfw) ?? false)
    blurNsfw = try (container.decodeIfPresent(Bool.self, forKey: .blurNsfw) ?? true)
    muteAudio = try (container.decodeIfPresent(Bool.self, forKey: .muteAudio) ?? true)
    autoPlayGifs = try (container.decodeIfPresent(Bool.self, forKey: .autoPlayGifs) ?? false)
    browser = try (container.decodeIfPresent(Browser.self, forKey: .browser) ?? .inApp)
    openLinksInForeground = try (container.decodeIfPresent(Bool.self, forKey: .openLinksInForeground) ?? true)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(hideNsfw, forKey: .hideNsfw)
    try container.encode(blurNsfw, forKey: .blurNsfw)
    try container.encode(muteAudio, forKey: .muteAudio)
    try container.encode(autoPlayGifs, forKey: .autoPlayGifs)
    try container.encode(browser, forKey: .browser)
    try container.encode(openLinksInForeground, forKey: .openLinksInForeground)
  }

  private func updateDefaults() {
    let data = try? JSONEncoder().encode(self)
    UserDefaults.standard.set(data, forKey: "preferences")
  }
}

// #if DEBUG
// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
// #endif
