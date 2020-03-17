//
// ResizingText.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/15/2020
//

import Combine
import SwiftUI

/// Works around `List` row height being fixed by setting the child frame's`height` when its `size` adjusts
extension View {
  func heightResizable() -> some View {
    self.modifier(HeightResizingModifier())
  }
}

private struct HeightResizingModifier: ViewModifier {
  @ObservedObject var reader = SizeReader()

  func body(content: Content) -> some View {
    content
      .fixedSize(horizontal: false, vertical: true)
      .background(SizeReaderRepresentable(view: reader))
      .frame(height: reader.readerBounds.height)
  }
}

private struct SizeReaderRepresentable: NSViewControllerRepresentable {
  let view: SizeReader

  func makeNSViewController(context: NSViewControllerRepresentableContext<SizeReaderRepresentable>) -> SizeReaderController {
    let controller = SizeReaderController()
    controller.view = view
    return controller
  }

  func updateNSViewController(_: SizeReaderController, context _: NSViewControllerRepresentableContext<SizeReaderRepresentable>) {}
}

private class SizeReaderController: NSViewController {
  override func viewDidAppear() {
    super.viewDidAppear()
    (self.view as! SizeReader).updateSize()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    (self.view as! SizeReader).updateSize()
  }

  override func preferredContentSizeDidChange(for viewController: NSViewController) {
    super.preferredContentSizeDidChange(for: viewController)
    (self.view as! SizeReader).updateSize()
  }
}

private class SizeReader: NSView, ObservableObject {
  @Published var readerBounds: NSRect = .zero

  init() {
    super.init(frame: .zero)
    self.autoresizingMask = [.height, .width]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateSize() {
    self.readerBounds = self.bounds
  }

  override func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    updateSize()
  }
}
