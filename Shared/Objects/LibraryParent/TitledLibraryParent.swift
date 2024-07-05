//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// A basic structure conforming to `LibraryParent` that is meant to only define its `displayTitle`
struct TitledLibraryParent: LibraryParent {

    let displayTitle: String
    let id: String? = nil
    let libraryType: BaseItemKind? = nil
}
