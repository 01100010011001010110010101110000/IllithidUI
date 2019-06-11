//
//  RemoteImage.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/11/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import AlamofireImage
import Illithid

struct RemoteImage: View {
  @State private var image: NSImage = NSImage(imageLiteralResourceName: "NSAdvanced")

  let url: URL
  let imageDownloader: ImageDownloader

  init(_ url: URL, imageDownloader: ImageDownloader) {
    self.url = url
    self.imageDownloader = imageDownloader
  }

  var body: some View {
    Image(nsImage: image)
      .bind(imageDownloader.imagePublisher(for: self.url), to: $image)
  }
}

#if DEBUG
struct RemoteImage_Previews: PreviewProvider {
  static var previews: some View {
    RemoteImage(URL(string: "https://upload.wikimedia.org/wikipedia/en/1/13/Illithid_Sorcerer.png")!,
                imageDownloader: .init())
  }
}
#endif

extension View {
  func bind<P: Publisher, Value>(_ publisher: P, to state: Binding<Value>)
    -> SubscriptionView<P, Self> where P.Failure == Never, P.Output == Value {
    return onReceive(publisher) { state.value = $0 }
  }
}
