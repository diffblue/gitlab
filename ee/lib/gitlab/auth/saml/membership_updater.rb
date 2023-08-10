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
          return enqueue_microsoft_group_sync if microsoft_overage_sync?

          enqueue_saml_group_sync if saml_group_sync?
        end

        def enqueue_saml_group_sync
          ::Auth::SamlGroupSyncWorker.perform_async(user.id, group_link_ids, auth_hash.provider)
        end

        def enqueue_microsoft_group_sync
          ::SystemAccess::SamlMicrosoftGroupSyncWorker.perform_async(user.id, auth_hash.provider)
        end

        def sync_groups?
          user && any_group_links?
        end

        def microsoft_overage_sync?
          auth_hash.azure_group_overage_claim? && microsoft_group_sync_available?
        end

        def saml_group_sync?
          saml_config.group_sync_enabled?
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

        def microsoft_group_sync_available?
          saml_config.microsoft_group_sync_enabled? &&
            instance_microsoft_application&.enabled?
        end

        def instance_microsoft_application
          SystemAccess::MicrosoftApplication.instance_application
        end
        strong_memoize_attr :instance_microsoft_application

        def saml_config
          Gitlab::Auth::Saml::Config.new(auth_hash.provider)
        end
        strong_memoize_attr :saml_config
      end
    end
  end
end
