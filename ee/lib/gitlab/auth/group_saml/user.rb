# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class User < Gitlab::Auth::OAuth::User
        include ::Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        attr_accessor :saml_provider
        attr_reader :auth_hash

        override :initialize
        def initialize(auth_hash)
          @auth_hash = AuthHash.new(auth_hash)
        end

        override :find_and_update!
        def find_and_update!
          add_or_update_user_identities
          set_provisioned_user_attributes!(gl_user)

          save("GroupSaml Provider ##{@saml_provider.id}")
          # Do not return un-persisted user so user is prompted
          # to sign-in to existing account.
          return unless valid_sign_in?

          update_group_membership
          gl_user
        end

        override :bypass_two_factor?
        def bypass_two_factor?
          false
        end

        override :identity_verification_enabled?
        def identity_verification_enabled?(_)
          false
        end

        private

        override :gl_user
        def gl_user
          strong_memoize(:gl_user) do
            identity&.user || find_by_email || build_new_user
          end
        end

        def identity
          strong_memoize(:identity) do
            ::Auth::GroupSamlIdentityFinder.new(saml_provider, auth_hash).first
          end
        end

        override :find_by_email
        def find_by_email
          user = super
          return unless user&.authorized_by_provisioning_group?(saml_provider.group)

          user
        end

        override :build_new_user
        def build_new_user(skip_confirmation: false)
          super.tap do |user|
            user.provisioned_by_group_id = saml_provider.group_id
            user.skip_confirmation_notification!
          end
        end

        override :user_attributes
        def user_attributes
          super.tap do |hash|
            hash[:extern_uid] = auth_hash.uid
            hash[:saml_provider_id] = @saml_provider.id
            hash[:provider] = ::Users::BuildService::GROUP_SAML_PROVIDER
            hash[:group_id] = saml_provider.group_id
          end
        end

        override :add_or_update_user_identities
        def add_or_update_user_identities
          return unless gl_user
          return if self.identity # extern_uid hasn't changed

          # find_or_initialize_by doesn't update `gl_user.identities`, and isn't autosaved.
          identity = gl_user.identities.find { |identity| identity.provider == auth_hash.provider && identity.saml_provider_id == @saml_provider.id }
          identity ||= gl_user.identities.build(provider: auth_hash.provider, saml_provider: @saml_provider)

          identity.extern_uid = auth_hash.uid

          identity
        end

        def update_group_membership
          MembershipUpdater.new(gl_user, saml_provider, auth_hash).execute
        end

        def set_provisioned_user_attributes!(user)
          return unless user.provisioned_by_group_id == saml_provider.group_id

          user.assign_attributes(auth_hash.user_attributes.compact)
        end

        override :block_after_signup?
        def block_after_signup?
          false
        end
      end
    end
  end
end
