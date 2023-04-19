# frozen_string_literal: true

class SamlProvider < ApplicationRecord
  USER_ATTRIBUTES_LOCKED_FOR_MANAGED_ACCOUNTS = %i(email public_email commit_email notification_email).freeze

  belongs_to :group
  has_many :identities

  validates :group, presence: true, top_level_group: true
  validates :sso_url, presence: true, addressable_url: { schemes: %w(https), ascii_only: true }
  validates :certificate_fingerprint, presence: true, certificate_fingerprint: true
  validates :default_membership_role, presence: true
  validate :git_check_enforced_allowed
  validate :access_level_inclusion

  after_initialize :set_defaults, if: :new_record?

  delegate :assertion_consumer_service_url, :issuer, :name_identifier_format, to: :defaults

  def certificate_fingerprint=(value)
    super(strip_left_to_right_chars(value))
  end

  def settings
    defaults.to_h.merge(
      idp_cert_fingerprint: certificate_fingerprint,
      idp_sso_target_url: sso_url,
      attribute_statements: { nickname: %w(username nickname) }
    )
  end

  def defaults
    @defaults ||= DefaultOptions.new(group.full_path)
  end

  def enforced_sso?
    enabled? && super && group.licensed_feature_available?(:group_saml)
  end

  def git_check_enforced?
    super && enforced_sso?
  end

  def enforced_group_managed_accounts?
    super && enforced_sso? && Feature.enabled?(:group_managed_accounts, group)
  end

  def prohibited_outer_forks?
    enforced_group_managed_accounts? && super
  end

  def last_linked_owner?(user)
    return false unless group.owned_by?(user)
    return false unless identities.for_user(user).exists?

    identities.for_user(group.owners).count == 1
  end

  class DefaultOptions
    include Gitlab::Routing

    NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'

    def initialize(group_path)
      @group_path = group_path
    end

    def name_identifier_format
      NAME_IDENTIFIER_FORMAT
    end

    def issuer
      group_canonical_url(@group_path)
    end

    def assertion_consumer_service_url
      callback_group_saml_providers_url(@group_path)
    end

    def to_h
      {
        assertion_consumer_service_url: assertion_consumer_service_url,
        issuer: issuer,
        name_identifier_format: name_identifier_format,
        idp_sso_service_url_runtime_params: { redirect_to: :RelayState },
        message_max_bytesize: Gitlab.config.omniauth.saml_message_max_byte_size
      }
    end
  end

  private

  def access_level_inclusion
    return errors.add(:default_membership_role, "is dependent on a group") unless group

    levels = group.access_level_values
    return if default_membership_role.in?(levels)

    errors.add(:default_membership_role, "is not included in the list")
  end

  def git_check_enforced_allowed
    return unless git_check_enforced
    return if enforced_sso?

    errors.add(:git_check_enforced, "is not allowed when SSO is not enforced.")
  end

  def set_defaults
    self.enabled = true
  end

  def strip_left_to_right_chars(input)
    input&.gsub(/\u200E/, '')
  end
end
