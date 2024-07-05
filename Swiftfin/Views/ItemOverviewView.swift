//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: fix with shorter text
//       - seems to center align

struct ItemOverviewView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    let item: BaseItemDto

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {

                if let firstTagline = item.taglines?.first {
                    Text(firstTagline)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                }

                if let itemOverview = item.overview {
                    Text(itemOverview)
                        .font(.body)
                }
            }
            .edgePadding()
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
