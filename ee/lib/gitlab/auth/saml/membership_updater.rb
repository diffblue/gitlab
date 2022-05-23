# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class MembershipUpdater
        include Gitlab::Utils::StrongMemoize

        def initialize(user, auth_hash)
          @user = user
          @auth_hash = auth_hash
        end

        def execute
          enqueue_group_sync if sync_groups?
        end

        private

        attr_reader :user, :auth_hash

        def enqueue_group_sync
          ::Auth::SamlGroupSyncWorker.perform_async(user.id, group_link_ids)
        end

        def sync_groups?
          return false unless user

          sync_enabled? && any_group_links?
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def group_link_ids
          strong_memoize(:group_link_ids) do
            next [] if group_names_from_saml.empty?

            SamlGroupLink
              .by_saml_group_name(group_names_from_saml)
              .pluck(:id)
          end
        end

        def any_group_links?
          strong_memoize(:any_group_links) do
            SamlGroupLink.any?
          end
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def group_names_from_saml
          strong_memoize(:group_names_from_saml) do
            auth_hash.groups || []
          end
        end

        def sync_enabled?
          Gitlab::Auth::Saml::Config.group_sync_enabled?
        end
      end
    end
  end
end
