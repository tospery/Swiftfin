//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

/// Magic number for page sizes
private let DefaultPageSize = 50

// TODO: fix how `hasNextPage` is determined
//       - some subclasses might not have "paging" and only have one call. This can be solved with
//         a check if elements were actually appended to the set but that requires a redundant get
// TODO: this doesn't allow "scrolling" to an item if index > pageSize
//       on refresh. Should make bidirectional/offset index start?
//       - use startIndex/index ranges instead of pages
//       - source of data doesn't guarantee that all items in 0 ..< startIndex exist
class PagingLibraryViewModel<Element: Poster>: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event: Equatable {
        case gotRandomItem(Element)
    }

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case refresh
        case getNextPage
        case getRandomItem
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case gettingNextPage
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var elements: OrderedSet<Element>
    @Published
    final var state: State = .initial
    @Published
    final var lastAction: Action? = nil

    final let filterViewModel: FilterViewModel?
    final let parent: (any LibraryParent)?

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    let pageSize: Int
    private(set) final var currentPage = 0
    private(set) final var hasNextPage = true

    private let eventSubject: PassthroughSubject<Event, Never> = .init()
    private let isStatic: Bool

    // tasks

    private var filterQueryTask: AnyCancellable?
    private var pagingTask: AnyCancellable?
    private var randomItemTask: AnyCancellable?

    // MARK: init

    // static
    init(
        _ data: some Collection<Element>,
        parent: (any LibraryParent)? = nil
    ) {
        self.filterViewModel = nil
        self.elements = OrderedSet(data)
        self.isStatic = true
        self.hasNextPage = false
        self.pageSize = DefaultPageSize
        self.parent = parent
    }

    convenience init(
        title: String,
        _ data: some Collection<Element>
    ) {
        self.init(data, parent: TitledLibraryParent(displayTitle: title))
    }

    // paging
    init(
        parent: (any LibraryParent)? = nil,
        filters: ItemFilterCollection? = nil,
        pageSize: Int = DefaultPageSize
    ) {
        self.elements = OrderedSet()
        self.isStatic = false
        self.pageSize = pageSize
        self.parent = parent

        if let filters {
            self.filterViewModel = .init(
                parent: parent,
                currentFilters: filters
            )
        } else {
            self.filterViewModel = nil
        }

        super.init()

        if let filterViewModel {
            filterViewModel.$currentFilters
                .dropFirst()
                .debounce(for: 1, scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] _ in
                    guard let self else { return }

                    Task { @MainActor in
                        self.send(.refresh)
                    }
                }
                .store(in: &cancellables)
        }
    }

    convenience init(
        title: String,
        filters: ItemFilterCollection = .default,
        pageSize: Int = DefaultPageSize
    ) {
        self.init(
            parent: TitledLibraryParent(displayTitle: title),
            filters: filters,
            pageSize: pageSize
        )
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        if action == .refresh, isStatic {
            return .content
        }

        switch action {
        case let .error(error):

            Task { @MainActor in
                elements.removeAll()
            }

            return .error(error)
        case .refresh:

            filterQueryTask?.cancel()
            pagingTask?.cancel()
            randomItemTask?.cancel()

            filterQueryTask = Task {
                await filterViewModel?.setQueryFilters()
            }
            .asAnyCancellable()

            pagingTask = Task { [weak self] in
                guard let self else { return }

                do {
                    try await self.refresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        case .getNextPage:

            guard hasNextPage else { return state }

            backgroundStates.append(.gettingNextPage)

            pagingTask = Task { [weak self] in
                do {
                    try await self?.getNextPage()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.backgroundStates.remove(.gettingNextPage)
                        self?.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.backgroundStates.remove(.gettingNextPage)
                        self?.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .content
        case .getRandomItem:

            randomItemTask = Task { [weak self] in
                do {
                    guard let randomItem = try await self?.getRandomItem() else { return }

                    guard !Task.isCancelled else { return }

                    self?.eventSubject.send(.gotRandomItem(randomItem))
                } catch {
                    // TODO: when a general toasting mechanism is implemented, add
                    //       background errors for errors from other background tasks
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: refresh

    final func refresh() async throws {

        currentPage = -1
        hasNextPage = true

        await MainActor.run {
            elements.removeAll()
        }

        try await getNextPage()
    }

    /// Gets the next page of items or immediately returns if
    /// there is not a next page.
    ///
    /// See `get(page:)` for the conditions that determine
    /// if there is a next page or not.
    final func getNextPage() async throws {
        guard hasNextPage else { return }

        currentPage += 1

        let pageItems = try await get(page: currentPage)

        hasNextPage = !(pageItems.count < DefaultPageSize)

        await MainActor.run {
            elements.append(contentsOf: pageItems)
        }
    }

    /// Gets the items at the given page. If the number of items
    /// is less than `DefaultPageSize`, then it is inferred that
    /// there is not a next page and subsequent calls to `getNextPage`
    /// will immediately return.
    func get(page: Int) async throws -> [Element] {
        []
    }

    /// Gets a random item from `elements`. Override if item should
    /// come from another source instead.
    func getRandomItem() async throws -> Element? {
        elements.randomElement()
    }
}
