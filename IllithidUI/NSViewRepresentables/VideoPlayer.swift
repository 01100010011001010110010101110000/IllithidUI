//
// {file}
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on {created}
//

import AVKit
import Combine
import SwiftUI

struct VideoPlayer: View {
  @ObservedObject var preferences: PreferencesData = .shared
  @ObservedObject private var view: PlayerView

  private let fullSize: NSSize

  init(url: URL, fullSize: NSSize = .zero) {
    self.fullSize = fullSize
    view = PlayerView(url: url)
    view.allowsPictureInPicturePlayback = true
    view.controlsStyle = .floating
    view.showsFullScreenToggleButton = false
    view.showsSharingServiceButton = true
    view.updatesNowPlayingInfoCenter = false
    view.videoGravity = .resizeAspect
    view.autoresizingMask = [.height, .width]
  }

  var body: some View {
    _VideoPlayer(view: self.view)
      .onDisappear {
        self.view.player?.pause()
      }
      .onAppear {
        self.view.player?.volume = self.preferences.muteAudio ? 0.0 : 100.0
      }
      .onReceive(view.$isReady, perform: { ready in
        if ready, self.preferences.autoPlayGifs {
          self.view.player?.play()
        }
      })
      .frame(idealWidth: min(view.size.width, fullSize.width), maxWidth: fullSize.width,
             idealHeight: min(view.size.height, fullSize.height), maxHeight: fullSize.height)
    }
}

private struct _VideoPlayer: NSViewRepresentable {
  var view: PlayerView

  init(view: PlayerView) {
    self.view = view
  }

  func makeNSView(context: NSViewRepresentableContext<_VideoPlayer>) -> PlayerView {
    view.self
  }

  func updateNSView(_ nsView: PlayerView, context: NSViewRepresentableContext<_VideoPlayer>) {}

  static func dismantleNSView(_ nsView: PlayerView, coordinator: ()) {
    nsView.cancel()
  }
}

private final class PlayerView: AVPlayerView, ObservableObject {
  @Published var size: NSSize = .zero
  @Published var isReady: Bool = false

  private var inverseAspectRatio: CGFloat = .zero
  fileprivate var cancelBag: [AnyCancellable] = []

  convenience init() {
    self.init(frame: .zero)
  }

  convenience init(player: AVPlayer) {
    self.init(frame: .zero)
    self.player = player
  }

  convenience init(url: URL) {
    self.init(frame: .zero)
    player = AVPlayer(url: url)
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    cancelBag.append(self.publisher(for: \.isReadyForDisplay)
      .receive(on: RunLoop.main)
      .sink { [weak self] ready in
        self?.isReady = ready
        if ready {
          guard let self = self else { return }
          let currentItem = self.player!.currentItem!
          self.inverseAspectRatio = currentItem.presentationSize.height / currentItem.presentationSize.width
          self.size = self.calculateFrame()
        }
      })
    cancelBag.append(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.player?.seek(to: .zero)
        self.player?.play()
      })
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    if self.isReadyForDisplay {
      self.size = self.calculateFrame()
    }
  }

  private func calculateFrame() -> NSSize {
    NSSize(width: bounds.size.width, height: (inverseAspectRatio * bounds.size.width))
  }

  func cancel() {
    while !cancelBag.isEmpty {
      cancelBag.popLast()?.cancel()
    }
  }
}

struct VideoPlayer_Previews: PreviewProvider {
  static var previews: some View {
    ForEach(["https://giant.gfycat.com/AbandonedFlatFox.mp4",
             "https://v.redd.it/qaiv863zjwl41/HLSPlaylist.m3u8"], id: \.self) { urlString in
              VideoPlayer(url: URL(string: urlString)!)
    }
  }
}

