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

import Combine
import SwiftUI
import WebKit

// MARK: - WebView

struct WebView: View {
  // MARK: Lifecycle

  init(url: URL) {
    webView = .init(url: url, configuration: Self.makeConfiguration())
  }

  init(html: String, relativeTo baseUrl: URL? = nil) {
    webView = .init(html: html, relativeTo: baseUrl, configuration: Self.makeConfiguration())
  }

  // MARK: Internal

  var body: some View {
    _WebViewRepresentable(view: webView)
  }

  // MARK: Fileprivate

  @ObservedObject fileprivate var webView: _WebView

  // MARK: Private

  private static func makeConfiguration() -> WKWebViewConfiguration {
    let configuration: WKWebViewConfiguration = .init()
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.websiteDataStore = .nonPersistent() // Web views are "private"
    return configuration
  }
}

// MARK: - _WebViewRepresentable

private final class _WebViewRepresentable: NSViewRepresentable {
  // MARK: Lifecycle

  init(view: _WebView) {
    self.view = view
  }

  // MARK: Internal

  let view: _WebView

  static func dismantleNSView(_ nsView: _WebView, coordinator _: ()) {
    nsView.load(URLRequest(url: URL(string: "about:blank")!))
    nsView.cancel()
  }

  func makeNSView(context _: NSViewRepresentableContext<_WebViewRepresentable>) -> _WebView {
    view
  }

  func updateNSView(_: _WebView, context _: NSViewRepresentableContext<_WebViewRepresentable>) {}
}

// MARK: - _WebView

private final class _WebView: WKWebView, ObservableObject {
  // MARK: Lifecycle

  convenience init(html: String, relativeTo baseUrl: URL?, configuration: WKWebViewConfiguration) {
    self.init(frame: .zero, configuration: configuration)
    loadHTMLString(html, baseURL: baseUrl)
    observe()
  }

  convenience init(url: URL, configuration: WKWebViewConfiguration) {
    self.init(frame: .zero, configuration: configuration)
    load(URLRequest(url: url))
    observe()
  }

  // MARK: Internal

  @Published var pageTitle: String? = nil
  @Published var loadProgress: Double = .zero

  func cancel() {
    while !cancelBag.isEmpty {
      cancelBag.popLast()?.cancel()
    }
  }

  // MARK: Private

  private var cancelBag: [AnyCancellable] = []

  private func observe() {
    cancelBag.append(publisher(for: \.title)
      .receive(on: RunLoop.main)
      .assign(to: \.pageTitle, on: self))
    cancelBag.append(publisher(for: \.title)
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] title in
        self?.window?.tab.title = title ?? (self?.window?.title ?? "")
      }))
    cancelBag.append(publisher(for: \.estimatedProgress)
      .receive(on: RunLoop.main)
      .assign(to: \.loadProgress, on: self))
  }
}

// MARK: - WebView_Previews

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    WebView(url: URL(string: "https://reddit.com")!)
  }
}
