//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import JellyfinAPI
import SwiftUI

struct ItemView: View {

    @StateObject
    private var viewModel: ItemViewModel

    private static func typeViewModel(for item: BaseItemDto) -> ItemViewModel {
        switch item.type {
        case .boxSet:
            return CollectionItemViewModel(item: item)
        case .episode:
            return EpisodeItemViewModel(item: item)
        case .movie:
            return MovieItemViewModel(item: item)
        case .series:
            return SeriesItemViewModel(item: item)
        default:
            assertionFailure("Unsupported item")
            return ItemViewModel(item: item)
        }
    }

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: Self.typeViewModel(for: item))
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.item.type {
        case .boxSet:
            CollectionItemView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            EpisodeItemView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            MovieItemView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                Text(error.localizedDescription)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .transition(.opacity.animation(.linear(duration: 0.2)))
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
