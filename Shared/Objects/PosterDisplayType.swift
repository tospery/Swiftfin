//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum PosterDisplayType: String, CaseIterable, Displayable, Defaults.Serializable {

    case landscape
    case portrait

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .landscape:
            "Landscape"
        case .portrait:
            "Portrait"
        }
    }
}
