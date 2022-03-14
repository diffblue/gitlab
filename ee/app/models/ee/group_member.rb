# frozen_string_literal: true

module EE
  module GroupMember
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics

      validate :sso_enforcement, if: -> { group && user }
      validate :group_domain_limitations, if: :group_has_domain_limitations?

      scope :by_group_ids, ->(group_ids) { where(source_id: group_ids) }

      scope :with_ldap_dn, -> { joins(user: :identities).where("identities.provider LIKE ?", 'ldap%') }
      scope :with_identity_provider, ->(provider) do
        joins(user: :identities).where(identities: { provider: provider })
      end
      scope :with_saml_identity, ->(provider) do
        joins(user: :identities).where(identities: { saml_provider_id: provider })
      end

      scope :reporters, -> { where(access_level: ::Gitlab::Access::REPORTER) }
      scope :guests, -> { where(access_level: ::Gitlab::Access::GUEST) }
      scope :non_owners, -> { where("members.access_level < ?", ::Gitlab::Access::OWNER) }
      scope :by_user_id, ->(user_id) { where(user_id: user_id) }
    end

    class_methods do
      def member_of_group?(group, user)
        exists?(group: group, user: user)
      end

      def filter_by_enterprise_users(value)
        subquery =
          ::UserDetail.where(
            ::UserDetail.arel_table[:provisioned_by_group_id].eq(arel_table[:source_id]).and(
              ::UserDetail.arel_table[:user_id].eq(arel_table[:user_id]))
          )

        if value
          where_exists(subquery)
        else
          where_not_exists(subquery)
        end
      end
    end

    def provisioned_by_this_group?
      user&.user_detail&.provisioned_by_group_id == source_id
    end

    private

    override :access_level_inclusion
    def access_level_inclusion
      levels = source.access_level_values
      return if access_level.in?(levels)

      errors.add(:access_level, "is not included in the list")

      if access_level == ::Gitlab::Access::MINIMAL_ACCESS
        errors.add(:access_level, "supported on top level groups only") if group.has_parent?
        errors.add(:access_level, "not supported by license") unless group.feature_available?(:minimal_access_role)
      end
    end

    override :post_create_hook
    def post_create_hook
      super

      if provisioned_by_this_group?
        run_after_commit_or_now do
          notification_service.new_group_member_with_confirmation(self)
        end
      end

      execute_hooks_for(:create)
    end

    override :post_update_hook
    def post_update_hook
      super

      if saved_change_to_access_level? || saved_change_to_expires_at?
        execute_hooks_for(:update)
      end
    end

    def post_destroy_hook
      super

      execute_hooks_for(:destroy)
    end

    def execute_hooks_for(event)
      return unless self.source.feature_available?(:group_webhooks)
      return unless GroupHook.where(group_id: self.source.self_and_ancestors).exists?

      run_after_commit do
        data = ::Gitlab::HookData::GroupMemberBuilder.new(self).build(event)
        self.source.execute_hooks(data, :member_hooks)
      end
    end

    override :send_welcome_email?
    def send_welcome_email?
      !provisioned_by_this_group?
    end
  end
end
