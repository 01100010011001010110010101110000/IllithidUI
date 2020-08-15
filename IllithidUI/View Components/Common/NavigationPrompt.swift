//
// NavigationPrompt.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/9/20
//

import SwiftUI

struct NavigationPrompt: View {
  let prompt: String
  var body: some View {
    Text(prompt)
      .font(.largeTitle)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct NavigationPrompt_Previews: PreviewProvider {
  static var previews: some View {
    NavigationPrompt(prompt: "Hello, I am a prompt")
  }
}
