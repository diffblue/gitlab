# frozen_string_literal: true

module EE
  module GroupMember
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics

      validate :sso_enforcement, if: :group
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
    end

    def group_has_domain_limitations?
      group.licensed_feature_available?(:group_allowed_email_domains) && group_allowed_email_domains.any?
    end

    def group_domain_limitations
      if user
        return if user.project_bot?

        validate_users_email
        validate_email_verified
      else
        validate_invitation_email
      end
    end

    def validate_email_verified
      return if user.primary_email_verified?

      # Do not validate if emails are verified
      # for users created via SAML/SCIM.
      return if group_saml_identity.present?
      return if source.scim_identities.for_user(user).exists?

      errors.add(:user, email_not_verified)
    end

    def validate_users_email
      return if matches_at_least_one_group_allowed_email_domain?(user.email)

      errors.add(:user, email_does_not_match_any_allowed_domains(user.email))
    end

    def validate_invitation_email
      return if matches_at_least_one_group_allowed_email_domain?(invite_email)

      errors.add(:invite_email, email_does_not_match_any_allowed_domains(invite_email))
    end

    def group_saml_identity
      return unless source.saml_provider

      if user.group_saml_identities.loaded?
        user.group_saml_identities.detect { |i| i.saml_provider_id == source.saml_provider.id }
      else
        user.group_saml_identities.find_by(saml_provider: source.saml_provider)
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
    end

    def email_does_not_match_any_allowed_domains(email)
      n_("email does not match the allowed domain of %{email_domains}", "email does not match the allowed domains: %{email_domains}", group_allowed_email_domains.size) %
        { email_domains: group_allowed_email_domains.map(&:domain).join(', ') }
    end

    def email_not_verified
      _("email '%{email}' is not a verified email." % { email: user.email })
    end

    def group_allowed_email_domains
      group.root_ancestor_allowed_email_domains
    end

    def matches_at_least_one_group_allowed_email_domain?(email)
      group_allowed_email_domains.any? do |allowed_email_domain|
        allowed_email_domain.email_matches_domain?(email)
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
