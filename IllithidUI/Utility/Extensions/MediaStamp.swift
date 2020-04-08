//
// MediaStamp.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/8/20
//

import SwiftUI

extension View {
  func mediaStamp(_ mediaType: String, alignment: Alignment = .bottomTrailing,
                  edges: Edge.Set = [.bottom, .trailing], inset: CGFloat = 4.0) -> some View {
    overlay(
      MediaStamp(mediaType: mediaType)
        .padding(edges, inset),
      alignment: alignment
    )
  }
}

struct MediaStamp: View {
  let mediaType: String

  var body: some View {
    Text(mediaType)
      .font(.caption)
      .foregroundColor(.black)
      .padding(4)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .foregroundColor(.white)
      )
  }
}

struct MediaStamp_Previews: PreviewProvider {
  static var previews: some View {
    MediaStamp(mediaType: "gfycat")
  }
}
