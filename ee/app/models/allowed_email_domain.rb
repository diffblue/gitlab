# frozen_string_literal: true

class AllowedEmailDomain < ApplicationRecord
  RESERVED_DOMAINS = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'aol.com',
    'msn.com',
    'hotmail.co.uk',
    'hotmail.fr',
    'live.com',
    'outlook.com',
    'icloud.com'
  ].freeze

  ##
  # NOTE: If we need to change this regex, we need to ensure we use the same regex in ruby and JS
  #
  # VALID_DOMAIN_BASE defines the core of the regex we use for validating email addresses
  # For ruby code we should use the `VALID_DOMAIN_REGEX` regex. The JS_VALID_DOMAIN_REGEX
  # should only be passed to the frontend for validation in javascript. This is because of
  # the differences in how ruby interprets `\A` and `\z`
  #
  # More information: https://gitlab.com/gitlab-org/gitlab/-/issues/321510
  #
  VALID_DOMAIN_BASE = '(?=.*\.)[0-9a-zA-Z.-]+'

  # VALID_DOMAIN_REGEX is the regex we should be using to validate email domains in ruby
  VALID_DOMAIN_REGEX = /\A#{VALID_DOMAIN_BASE}\z/.freeze

  # JS_VALID_DOMAIN_REGEX is only for use on the frontend in javascript/vue
  JS_VALID_DOMAIN_REGEX = /^#{VALID_DOMAIN_BASE}$/.freeze

  validates :group_id, presence: true
  validates :domain, presence: true
  validate :allow_root_group_only
  validates :domain, exclusion: { in: RESERVED_DOMAINS,
                                  message: N_('The domain you entered is not allowed.') }
  validates :domain, if: :domain_changed?, format: { with: VALID_DOMAIN_REGEX,
                                                     message: N_('The domain you entered is misformatted.') }

  belongs_to :group, class_name: 'Group', foreign_key: :group_id

  class << self
    def domain_names
      pluck(:domain)
    end
  end

  def allow_root_group_only
    if group&.parent_id
      errors.add(:base, _('Allowed email domain restriction only permitted for top-level groups'))
    end
  end

  def email_matches_domain?(email)
    email.end_with?(email_domain)
  end

  def email_domain
    @email_domain ||= "@#{domain}"
  end
end
