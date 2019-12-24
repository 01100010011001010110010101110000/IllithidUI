//
// RemoteImage.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import SwiftUI

import AlamofireImage
import Illithid

struct RemoteImage: View {
  @State private var image: NSImage = NSImage(imageLiteralResourceName: "NSAdvanced")
  @EnvironmentObject var imageDownloader: ImageDownloader

  let url: URL
  let resizable: Bool

  init(_ url: URL, resizable: Bool = false) {
    self.url = url
    self.resizable = resizable
  }

  var body: some View {
    if resizable {
      return Image(nsImage: image)
        .resizable()
        .bind(imageDownloader.imagePublisher(for: self.url), to: $image)
    } else {
      return Image(nsImage: image)
        .bind(imageDownloader.imagePublisher(for: self.url), to: $image)
    }
  }
}

#if DEBUG
  struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
      RemoteImage(URL(string: "https://upload.wikimedia.org/wikipedia/en/1/13/Illithid_Sorcerer.png")!)
        .environmentObject(ImageDownloader())
    }
  }
#endif

extension View {
  func bind<P: Publisher, Value>(_ publisher: P, to state: Binding<Value>)
    -> some View where P.Failure == Never, P.Output == Value {
    return onReceive(publisher) { state.wrappedValue = $0 }
  }
}

extension ImageDownloader: ObservableObject {}
