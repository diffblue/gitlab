# frozen_string_literal: true

module SystemAccess
  class SamlMicrosoftGroupSyncWorker < BaseGlobalGroupSyncWorker
    include ::ApplicationWorker
    include ::Gitlab::Utils::StrongMemoize

    feature_category :system_access
    idempotent!
    urgency :low
    data_consistency :always

    def perform(user_id, provider = 'saml')
      self.user = User.find_by_id(user_id)
      self.provider = provider

      return unless user && group_sync_enabled?
      return unless microsoft_groups.any? && group_links.any?

      sync_groups
    end

    private

    attr_accessor :provider, :user

    def group_sync_enabled?
      ::Gitlab::Auth::Saml::Config.new(@provider).microsoft_group_sync_enabled? &&
        application&.enabled? &&
        microsoft_user_object_id.present?
    end

    def application
      SystemAccess::MicrosoftApplication.instance_application
    end
    strong_memoize_attr :application

    def client
      ::Microsoft::GraphClient.new(application)
    end
    strong_memoize_attr :client

    def microsoft_groups
      client.user_group_membership_object_ids(microsoft_user_object_id)
    end
    strong_memoize_attr :microsoft_groups

    def microsoft_user_object_id
      identity = user.identities.with_provider(provider)&.first
      identity&.extern_uid
    end
    strong_memoize_attr :microsoft_user_object_id

    def group_links
      SamlGroupLink
        .by_saml_group_name(microsoft_groups)
        .preload_group
    end
  end
end
