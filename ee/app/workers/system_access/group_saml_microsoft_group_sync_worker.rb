# frozen_string_literal: true

module SystemAccess
  class GroupSamlMicrosoftGroupSyncWorker < BaseSaasGroupSyncWorker
    include ::ApplicationWorker
    include ::Gitlab::Utils::StrongMemoize

    feature_category :system_access
    idempotent!
    urgency :low
    data_consistency :always

    def perform(user_id, top_level_group_id)
      self.user = User.find_by_id(user_id)
      self.top_level_group = Group.by_parent(nil).find_by_id(top_level_group_id)

      return unless user && top_level_group && group_sync_enabled?
      return unless microsoft_groups.any? && group_links.any?

      sync_and_update_default_membership
    end

    private

    def group_sync_enabled?
      top_level_group.group_saml_enabled? &&
        top_level_group.licensed_feature_available?(:microsoft_group_sync) &&
        application&.enabled? &&
        microsoft_user_object_id.present?
    end

    def client
      ::Microsoft::GraphClient.new(application)
    end
    strong_memoize_attr :client

    def application
      top_level_group.system_access_microsoft_application
    end

    def microsoft_user_object_id
      identity = user.group_saml_identities.find_by_saml_provider_id(top_level_group.saml_provider.id)
      identity&.extern_uid
    end
    strong_memoize_attr :microsoft_user_object_id

    def microsoft_groups
      client.user_group_membership_object_ids(microsoft_user_object_id)
    end
    strong_memoize_attr :microsoft_groups

    def group_links
      SamlGroupLink
        .by_saml_group_name(microsoft_groups)
        .by_group_id(group_ids_in_hierarchy)
        .preload_group
    end
  end
end
