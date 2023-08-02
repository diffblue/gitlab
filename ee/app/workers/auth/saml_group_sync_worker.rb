# frozen_string_literal: true

# Self-managed SAML Group Sync Worker
#
# When a user signs in with SAML this worker will
# be triggered to manage that user's group membership.
module Auth
  class SamlGroupSyncWorker < ::SystemAccess::BaseGlobalGroupSyncWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :always

    feature_category :system_access
    idempotent!

    loggable_arguments 1

    def perform(user_id, group_link_ids, provider = 'saml')
      @group_link_ids = group_link_ids
      @user = User.find_by_id(user_id)
      @provider = provider

      return unless user && sync_enabled? && groups_to_sync?

      sync_groups
    end

    private

    attr_reader :group_link_ids, :user

    def sync_enabled?
      Gitlab::Auth::Saml::Config.new(@provider).group_sync_enabled?
    end

    def group_links
      strong_memoize(:group_links) do
        SamlGroupLink.id_in(group_link_ids).preload_group
      end
    end
  end
end
