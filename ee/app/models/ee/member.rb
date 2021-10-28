# frozen_string_literal: true

module EE
  module Member
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      STATE_CREATED = 0
      STATE_AWAITING = 1
      STATE_ACTIVE = 2

      state_machine :state, initial: :created do
        event :wait do
          transition created: :awaiting
          transition active: :awaiting
        end

        event :activate do
          transition created: :active
          transition awaiting: :active
        end

        state :created, value: STATE_CREATED
        state :awaiting, value: STATE_AWAITING
        state :active, value: STATE_ACTIVE
      end
      scope :awaiting, -> {where(state: STATE_AWAITING)}
      scope :non_awaiting, -> {where.not(state: STATE_AWAITING)}

      before_create :set_membership_activation

      after_commit :invalidate_namespace_user_cap_cache

      scope :with_csv_entity_associations, -> do
        includes(:user, source: [:route, :parent])
      end
    end

    override :notification_service
    def notification_service
      if ldap
        # LDAP users shouldn't receive notifications about membership changes
        ::EE::NullNotificationService.new
      else
        super
      end
    end

    def sso_enforcement
      unless ::Gitlab::Auth::GroupSaml::MembershipEnforcer.new(group).can_add_user?(user)
        errors.add(:user, 'is not linked to a SAML account')
      end
    end

    # The method is exposed in the API as is_using_seat
    # in ee/lib/ee/api/entities.rb
    #
    # rubocop: disable Naming/PredicateName
    def is_using_seat
      return user.using_gitlab_com_seat?(source) if ::Gitlab.com?

      user.using_license_seat?
    end
    # rubocop: enable Naming/PredicateName

    def source_kind
      source.is_a?(Group) && source.parent.present? ? 'Sub group' : source.class.to_s
    end

    def group_has_domain_limitations?
      return false unless group

      group.licensed_feature_available?(:group_allowed_email_domains) && group_allowed_email_domains.any?
    end

    def group_domain_limitations
      return unless group

      if user
        return if user.project_bot?

        validate_users_email
        validate_email_verified
      else
        validate_invitation_email
      end
    end

    def group_saml_identity(root_ancestor: false)
      saml_group = root_ancestor ? group.root_ancestor : group

      return unless saml_group.saml_provider

      if user.group_saml_identities.loaded?
        user.group_saml_identities.detect { |i| i.saml_provider_id == saml_group.saml_provider.id }
      else
        user.group_saml_identities.find_by(saml_provider: saml_group.saml_provider)
      end
    end

    private

    def group_allowed_email_domains
      return [] unless group

      group.root_ancestor_allowed_email_domains
    end

    def validate_users_email
      return if matches_at_least_one_group_allowed_email_domain?(user.email)

      errors.add(:user, email_does_not_match_any_allowed_domains(user.email))
    end

    def validate_invitation_email
      return if matches_at_least_one_group_allowed_email_domain?(invite_email)

      errors.add(:invite_email, email_does_not_match_any_allowed_domains(invite_email))
    end

    def validate_email_verified
      return if user.primary_email_verified?

      return if group_saml_identity(root_ancestor: true).present?
      return if group.root_ancestor.scim_identities.for_user(user).exists?

      errors.add(:user, email_not_verified)
    end

    def email_does_not_match_any_allowed_domains(email)
      msg_1 = signup_email_invalid_message

      msg_2 = error_message[created_by_key][:group_setting]

      [msg_1, msg_2].join(' ')
    end

    def matches_at_least_one_group_allowed_email_domain?(email)
      group_allowed_email_domains.any? do |allowed_email_domain|
        allowed_email_domain.email_matches_domain?(email)
      end
    end

    def email_not_verified
      _("email '%{email}' is not a verified email." % { email: user.email })
    end

    def set_membership_activation
      return unless group && ::Feature.enabled?(:saas_user_caps, group.root_ancestor, default_enabled: :yaml)

      self.state = group.user_cap_reached? ? STATE_AWAITING : STATE_ACTIVE
    end

    def invalidate_namespace_user_cap_cache
      return unless group && ::Feature.enabled?(:saas_user_caps, group.root_ancestor, default_enabled: :yaml)

      Rails.cache.delete(group.namespace_user_cap_reached_cache_key)
    end
  end
end
