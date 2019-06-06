//
//  PostsView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/5/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

struct PostsView : View {
    var body: some View {
        Image("NSAdvanced").frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct PostsView_Previews : PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
#endif
