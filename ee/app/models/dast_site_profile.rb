# frozen_string_literal: true

class DastSiteProfile < ApplicationRecord
  belongs_to :project
  belongs_to :dast_site

  has_many :secret_variables, class_name: 'Dast::SiteProfileSecretVariable'

  validates :excluded_urls, length: { maximum: 25 }
  validates :auth_url, addressable_url: true, length: { maximum: 1024 }, allow_nil: true
  validates :auth_username_field, :auth_password_field, :auth_username, length: { maximum: 255 }
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true
  validates :project_id, :dast_site_id, presence: true

  validate :dast_site_project_id_fk
  validate :excluded_urls_contains_valid_urls
  validate :excluded_urls_contains_valid_strings

  scope :with_dast_site_and_validation, -> { includes(dast_site: :dast_site_validation) }
  scope :with_name, -> (name) { where(name: name) }

  after_destroy :cleanup_dast_site

  enum target_type: { website: 0, api: 1 }

  delegate :dast_site_validation, to: :dast_site, allow_nil: true

  def self.names(site_profile_ids)
    find(*site_profile_ids).pluck(:name)
  rescue ActiveRecord::RecordNotFound
    []
  end

  def ci_variables
    url = dast_site.url

    collection = ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
      if target_type == 'website'
        variables.append(key: 'DAST_WEBSITE', value: url)
      else
        variables.append(key: 'DAST_API_SPECIFICATION', value: url)
        variables.append(key: 'DAST_API_HOST_OVERRIDE', value: URI(url).host)
      end

      variables.append(key: 'DAST_EXCLUDE_URLS', value: excluded_urls.join(',')) unless excluded_urls.empty?

      if auth_enabled
        variables.append(key: 'DAST_AUTH_URL', value: auth_url)
        variables.append(key: 'DAST_USERNAME', value: auth_username)
        variables.append(key: 'DAST_USERNAME_FIELD', value: auth_username_field)
        variables.append(key: 'DAST_PASSWORD_FIELD', value: auth_password_field)
      end
    end

    collection.compact
  end

  def secret_ci_variables(user)
    collection = ::Gitlab::Ci::Variables::Collection.new

    return collection unless Ability.allowed?(user, :read_on_demand_scans, self)

    collection.concat(secret_variables)
  end

  def status
    return DastSiteValidation::NONE_STATE unless dast_site_validation

    dast_site_validation.state
  end

  def referenced_in_security_policies
    return [] unless project.security_orchestration_policy_configuration.present?

    project.security_orchestration_policy_configuration.active_policy_names_with_dast_site_profile(name)
  end

  private

  def cleanup_dast_site
    dast_site.destroy if dast_site.dast_site_profiles.empty?
  end

  def dast_site_project_id_fk
    unless project_id == dast_site&.project_id
      errors.add(:project_id, 'does not match dast_site.project')
    end
  end

  def excluded_urls_contains_valid_urls
    validate_excluded_urls_with("contains invalid URLs (%{urls})") do |excluded_url|
      !Gitlab::UrlSanitizer.valid?(excluded_url)
    end
  end

  def excluded_urls_contains_valid_strings
    validate_excluded_urls_with("contains URLs that exceed the 1024 character limit (%{urls})") do |excluded_url|
      excluded_url.length > 1024
    end
  end

  def validate_excluded_urls_with(message, &block)
    return if excluded_urls.blank?

    invalid = excluded_urls.select(&block)

    return if invalid.empty?

    errors.add(:excluded_urls, message % { urls: invalid.join(', ') })
  end
end
