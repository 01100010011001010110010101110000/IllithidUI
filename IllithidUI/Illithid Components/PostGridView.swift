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

// MARK: - PostGridView

struct PostGridView: View {
  // MARK: Internal

  @Environment(\.postStyle) var postStyle: PostStyle
  @EnvironmentObject var informationBarData: InformationBarData

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      HStack {
        HSplitView {
          ForEach(columnManager.columns) { column in
            SubredditSelectorView(column: column, onExit: { columnManager.removeColumn(id: $0) })
              .frame(minWidth: 300, maxWidth: 1400)
          }
        }
        .environmentObject(informationBarData)
        .environmentObject(columnManager)
        Spacer()
      }
      AddColumnButton(manager: columnManager)
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      informationBarData.loadAccountData()
    }
  }

  // MARK: Private

  private struct AddColumnButton: View {
    // MARK: Lifecycle

    init(manager columnManager: ColumnManager) {
      self.columnManager = columnManager
    }

    // MARK: Internal

    let columnManager: ColumnManager

    var body: some View {
      Button(action: {
        columnManager.addColumn()
      }, label: {
        Image(systemName: "plus")
      })
        .keyboardShortcut(.rightArrow)
        .shadow(radius: 20)
        .help("Add a column")
    }
  }

  @StateObject private var columnManager = ColumnManager()
}

// MARK: - NavigationSidebar

private struct NavigationSidebar: View {
  // MARK: Lifecycle

  init(column: ColumnManager.Column) {
    self.column = column
    _selection = .init(initialValue: column.selection)
  }

  // MARK: Internal

  @EnvironmentObject var informationBarData: InformationBarData
  @EnvironmentObject var columnManager: ColumnManager
  let column: ColumnManager.Column

  var body: some View {
    List(selection: $selection) {
      Section(header: Text("Meta")) {
        Label("Account", systemImage: "person.crop.circle")
          .help("Account view")
          .tag("__account__")
          .openableInNewTab(id: Illithid.shared.accountManager.currentAccount?.id ?? "account",
                            title: Illithid.shared.accountManager.currentAccount?.name ?? "Account") {
            accountView
          }
        Label("Search", systemImage: "magnifyingglass")
          .help("Search Reddit")
          .tag("__search__")
          .openableInNewTab(id: "search", title: "Search") { SearchView() }
      }
      Section(header: Text("Front Page")) {
        ForEach(FrontPage.allCases) { page in
          Label(page.title, systemImage: page.systemImageIconName)
            .help(page.displayName)
            .tag(page)
            .openableInNewTab(id: page.id, title: page.title) { PostListView(postContainer: page) }
        }
      }

      Section(header: Text("Multireddits")) {
        ForEach(filteredPostProviders(informationBarData.multireddits)) { multireddit in
          HStack {
            SubredditIcon(multireddit: multireddit)
              .frame(width: 24, height: 24)
            Text(multireddit.displayName)
          }
          .sheet(item: $editing) { multireddit in
            VStack {
              MultiredditEditView(editing: multireddit)
              HStack {
                Spacer()
                Button(action: {
                  editing = nil
                }) {
                  Text("done")
                }
                .keyboardShortcut(.cancelAction)
                .padding([.trailing, .bottom])
              }
            }
          }
          .help(multireddit.displayName)
          .tag("m/\(multireddit.id)")
          .openableInNewTab(id: multireddit.id, title: multireddit.name) { PostListView(postContainer: multireddit) }
          .contextMenu {
            Button(action: {
              editing = multireddit
            }) {
              Text("multireddit.edit")
            }
          }
        }
      }

      Section(header: Text("Subscribed")) {
        ForEach(filteredPostProviders(informationBarData.subscribedSubreddits)) { subreddit in
          HStack {
            SubredditIcon(subreddit: subreddit)
              .frame(width: 24, height: 24)
            Text(subreddit.displayName)
          }
          .openableInNewTab(id: subreddit.id, title: subreddit.displayName) { PostListView(postContainer: subreddit) }
          .help(subreddit.displayName)
          .tag(subreddit.id)
        }
      }
    }
    .listStyle(SidebarListStyle())
    .preference(key: NavigationSelectionPreferenceKey.self,
                value: selection)
    .onReceive(columnManager.$columns) { columns in
      if let column = columns.first(where: { $0 == column }), column.selection != self.column.selection {
        self.selection = column.selection
      }
    }
  }

  // MARK: Private

  @State private var selection: String?
  @State private var editing: Multireddit? = nil
  @ObservedObject private var preferences: PreferencesData = .shared

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
    } else {
      Text("There is no logged in account")
    }
  }

  private func filteredPostProviders<Provider: PostProvider>(_ providers: [Provider]) -> [Provider] {
    if preferences.hideNsfw {
      return providers.filter { !$0.isNsfw }
    } else {
      return providers
    }
  }
}

// MARK: - SubredditSelectorView

private struct SubredditSelectorView: View {
  // MARK: Lifecycle

  init(column: ColumnManager.Column, onExit: @escaping (UUID) -> Void) {
    self.column = column
    _selection = .init(initialValue: column.selection)
    self.onExit = onExit
  }

  // MARK: Internal

  @EnvironmentObject var columnManager: ColumnManager
  @EnvironmentObject var informationBarData: InformationBarData
  let column: ColumnManager.Column
  let onExit: (UUID) -> Void

  @ViewBuilder var body: some View {
    VStack {
      HStack {
        if column.closable {
          Button(action: {
            onExit(column.id)
          }, label: {
            Image(systemName: "xmark.circle.fill")
          })
            .keyboardShortcut(.cancelAction)
        }
        Spacer()
        Group {
          if let selection = column.selection {
            Text(informationBarData.displayName(forId: selection) ?? selection)
          } else {
            Text("Select")
          }
          Image(systemName: "chevron.down")
        }
        .font(.title)
        Spacer()
      }
      .padding()
      .onTapGesture {
        presentSelector = true
      }
      .popover(isPresented: $presentSelector) {
        List(selection: $selection) {
          Section(header: Text("Meta")) {
            Label("Account", systemImage: "person.crop.circle")
              .help("Account view")
              .tag("__account__")
            Label("Search", systemImage: "magnifyingglass")
              .help("Search Reddit")
              .tag("__search__")
          }
          Divider()
          Section(header: Text("Front Page")) {
            ForEach(FrontPage.allCases) { page in
              Label(page.title, systemImage: page.systemImageIconName)
                .help(page.displayName)
                .tag(page)
            }
          }
          Divider()
          Section(header: Text("Multireddits")) {
            ForEach(filteredPostProviders(informationBarData.multireddits)) { multireddit in
              HStack {
                SubredditIcon(multireddit: multireddit)
                  .frame(width: 24, height: 24)
                Text(multireddit.displayName)
              }
              .help(multireddit.displayName)
              .tag("m/\(multireddit.id)")
            }
          }
          Divider()
          Section(header: Text("Subscribed")) {
            ForEach(filteredPostProviders(informationBarData.subscribedSubreddits)) { subreddit in
              HStack {
                SubredditIcon(subreddit: subreddit)
                  .frame(width: 24, height: 24)
                Text(subreddit.displayName)
              }
              .help(subreddit.displayName)
              .tag(subreddit.id)
            }
          }
        }
      }
      .onChange(of: selection) { selected in
        columnManager.setSelection(for: column, selection: selected)
      }

      Divider()
        .padding(.horizontal)

      // TODO: Fix this idiotic hacky workaround
      if column.selection == "__account__" {
        accountView
      } else if column.selection == "__search__" {
        SearchView()
      } else if let page = selectedPage {
        if reload {
          PostListView(postContainer: page)
        } else {
          PostListView(postContainer: page)
        }
      } else if let multireddit = selectedMultireddit {
        if reload {
          PostListView(postContainer: multireddit)
        } else {
          PostListView(postContainer: multireddit)
        }
      } else if let subreddit = selectedSubreddit {
        if reload {
          PostListView(postContainer: subreddit)
        } else {
          PostListView(postContainer: subreddit)
        }
      } else {
        Spacer()
      }
    }
    .onChange(of: column.selection) { _ in
      reload.toggle()
    }
  }

  // MARK: Private

  @State private var selection: String?
  @State private var reload: Bool = false
  @State private var presentSelector: Bool = false
  @ObservedObject private var preferences: PreferencesData = .shared

  private var selectedSubreddit: Subreddit? {
    guard let selection = column.selection else { return nil }
    return informationBarData.subscribedSubreddits.first { $0.id == selection }
  }

  private var selectedMultireddit: Multireddit? {
    guard let selection = column.selection else { return nil }
    return informationBarData.multireddits.first { $0.id == selection }
  }

  private var selectedPage: FrontPage? {
    guard let selection = column.selection else { return nil }
    return FrontPage.allCases.first { $0.id == selection }
  }

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
    } else {
      Text("There is no logged in account")
    }
  }

  private func filteredPostProviders<Provider: PostProvider>(_ providers: [Provider]) -> [Provider] {
    if preferences.hideNsfw {
      return providers.filter { !$0.isNsfw }
    } else {
      return providers
    }
  }
}

// MARK: - ColumnManager

private final class ColumnManager: ObservableObject {
  // MARK: Lifecycle

  init() {
    guard let data = UserDefaults.standard.data(forKey: Self.columnKey),
          let saved = try? JSONDecoder().decode([Column].self, from: data) else {
      columns = [Column(closable: false, selection: "__search__")]
      return
    }
    columns = saved
  }

  // MARK: Internal

  struct Column: Identifiable, Codable, Equatable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), closable: Bool = true, selection: String = "__search__") {
      self.id = id
      self.closable = closable
      self.selection = selection
    }

    // MARK: Internal

    let id: UUID
    let closable: Bool
    var selection: String?
  }

  static let columnKey: String = "postGridView.columns"

  @Published var columns: [Column] {
    didSet {
      guard let data = try? JSONEncoder().encode(columns) else {
        return
      }

      UserDefaults.standard.set(data, forKey: Self.columnKey)
    }
  }

  func addColumn() {
    columns.append(Column())
  }

  func addColumn(selection: String) {
    DispatchQueue.main.async {
      self.columns.append(Column(selection: selection))
    }
  }

  func column(with id: UUID) -> Column? {
    columns.first { $0.id == id }
  }

  func setSelection(for column: Column, selection: String?) {
    guard let idx = columns.firstIndex(where: { $0.id == column.id }) else { return }
    columns[idx].selection = selection
  }

  func setSelection(for id: UUID, selection: String?) {
    guard let idx = columns.firstIndex(where: { $0.id == id }) else { return }
    columns[idx].selection = selection
  }

  func removeColumn(id: UUID) {
    columns.removeAll { $0.id == id }
  }

  @discardableResult
  func removeLast() -> Column? {
    columns.popLast()
  }
}
