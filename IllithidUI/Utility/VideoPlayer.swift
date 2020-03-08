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

  init(url: URL) {
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
      .frame(idealWidth: view.size.width, maxWidth: max(view.fullSize.width, view.size.width),
             idealHeight: view.size.height, maxHeight: max(view.fullSize.height, view.size.height))
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
}

private final class PlayerView: AVPlayerView, ObservableObject {
  @Published var size: NSSize = .zero
  @Published var fullSize: NSSize = .init(width: 3840, height: 2160)
  @Published var isReady: Bool = false

  var inverseAspectRatio: CGFloat = .zero

  private var presentationToken: AnyCancellable?
  private var readyToken: AnyCancellable?
  private var didEndToken: AnyCancellable?

  convenience init() {
    self.init(frame: .zero)
  }

  convenience init(url: URL) {
    self.init(frame: .zero)
    player = AVPlayer(url: url)

    readyToken = self.publisher(for: \.isReadyForDisplay)
      .receive(on: RunLoop.main)
      .assign(to: \.isReady, on: self)
    presentationToken = self.publisher(for: \.player?.currentItem?.presentationSize)
      .receive(on: RunLoop.main)
      .sink { size in
        self.fullSize = size ?? .zero
        self.size = self.fullSize
        self.inverseAspectRatio = self.fullSize.height / self.fullSize.width
      }
    didEndToken = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
      .receive(on: RunLoop.main)
      .sink { _ in
        self.player?.seek(to: .zero)
        self.player?.play()
      }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    if self.isReadyForDisplay, fullSize != .zero {
      self.size = NSSize(width: bounds.size.width,
                         height: (self.inverseAspectRatio * bounds.size.width))
    }
  }

  deinit {
    presentationToken?.cancel()
    readyToken?.cancel()
    didEndToken?.cancel()
  }
}

//struct VideoPlayer_Previews: PreviewProvider {
//  static var previews: some View {
//    VideoPlayer()
//  }
//}

