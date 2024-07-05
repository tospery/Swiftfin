//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeItemView: View {

    @ObservedObject
    var viewModel: EpisodeItemViewModel

    var body: some View {
        ScrollView {
            ContentView(viewModel: viewModel)
                .edgePadding(.bottom)
        }
    }
}
