//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import Logging

extension BaseItemDto {

    func videoPlayerViewModel(with mediaSource: MediaSourceInfo) async throws -> VideoPlayerViewModel {

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        // TODO: fix bitrate settings
        let tempOverkillBitrate = 360_000_000
        let profile = DeviceProfile.build(for: currentVideoPlayerType, maxBitrate: tempOverkillBitrate)

        let userSession = Container.userSession()

        let playbackInfo = PlaybackInfoDto(deviceProfile: profile)
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: userSession.user.id,
            maxStreamingBitrate: tempOverkillBitrate
        )

        let request = Paths.getPostedPlaybackInfo(
            itemID: self.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        let response = try await userSession.client.send(request)

        guard let matchingMediaSource = response.value.mediaSources?
            .first(where: { $0.eTag == mediaSource.eTag && $0.id == mediaSource.id })
        else {
            throw JellyfinAPIError("Matching media source not in playback info")
        }

        return try matchingMediaSource.videoPlayerViewModel(with: self, playSessionID: response.value.playSessionID!)
    }

    func liveVideoPlayerViewModel(with mediaSource: MediaSourceInfo, logger: Logger) async throws -> VideoPlayerViewModel {

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        // TODO: fix bitrate settings
        let tempOverkillBitrate = 360_000_000
        var profile = DeviceProfile.build(for: currentVideoPlayerType, maxBitrate: tempOverkillBitrate)
        if Defaults[.Experimental.liveTVForceDirectPlay] {
            profile.directPlayProfiles = [DirectPlayProfile(type: .video)]
        }

        let userSession = Container.userSession.callAsFunction()

        let playbackInfo = PlaybackInfoDto(deviceProfile: profile)
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: userSession.user.id,
            maxStreamingBitrate: tempOverkillBitrate
        )

        let request = Paths.getPostedPlaybackInfo(
            itemID: self.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        let response = try await userSession.client.send(request)
        logger.debug("liveVideoPlayerViewModel response received")

        var matchingMediaSource: MediaSourceInfo?
        if let responseMediaSources = response.value.mediaSources {
            for responseMediaSource in responseMediaSources {
                if let openToken = responseMediaSource.openToken, let mediaSourceId = mediaSource.id {
                    if openToken.contains(mediaSourceId) {
                        logger.debug("liveVideoPlayerViewModel found mediaSource with through openToken mediaSourceId match")
                        matchingMediaSource = responseMediaSource
                    }
                }
            }
            if matchingMediaSource == nil && !responseMediaSources.isEmpty {
                // Didn't find a match, but maybe we can just grab the first item in the response
                matchingMediaSource = responseMediaSources.first
                logger.debug("liveVideoPlayerViewModel resorting to first media source in the response")
            }
        }
        guard let matchingMediaSource else {
            logger.debug("liveVideoPlayerViewModel no matchingMediaSource found, throwing error")
            throw JellyfinAPIError("Matching media source not in playback info")
        }

        logger.debug("liveVideoPlayerViewModel matchingMediaSource being returned")
        return try matchingMediaSource.liveVideoPlayerViewModel(
            with: self,
            playSessionID: response.value.playSessionID!
        )
    }
}
