//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import UIKit

enum LibraryDisplayType: String, CaseIterable, Displayable, Defaults.Serializable, SystemImageable {

    case grid
    case list

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .grid:
            "Grid"
        case .list:
            "List"
        }
    }

    var systemImage: String {
        switch self {
        case .grid:
            "square.grid.2x2.fill"
        case .list:
            "square.fill.text.grid.1x2"
        }
    }
}
