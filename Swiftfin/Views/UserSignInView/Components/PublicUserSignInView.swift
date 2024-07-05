//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserSignInView {
    struct PublicUserSignInView: View {
        @ObservedObject
        var viewModel: UserSignInViewModel

        @State
        private var password: String = ""

        let publicUser: UserDto

        var body: some View {
            DisclosureGroup {
                SecureField(L10n.password, text: $password)
                Button {
                    guard let username = publicUser.name else { return }
                    viewModel.send(.signInWithUserPass(username: username, password: password))
                } label: {
                    L10n.signIn.text
                }
            } label: {
                HStack {
                    ImageView(publicUser.profileImageSource(client: viewModel.client, maxWidth: 50, maxHeight: 50))
                        .failure {
                            Image(systemName: "person.circle")
                                .resizable()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())

                    Text(publicUser.name ?? .emptyDash)
                    Spacer()
                }
            }
        }
    }
}
