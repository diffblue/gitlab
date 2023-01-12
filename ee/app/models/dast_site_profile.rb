# frozen_string_literal: true

class DastSiteProfile < ApplicationRecord
  API_SECRETS_KEYS = [Dast::SiteProfileSecretVariable::PASSWORD,
                      Dast::SiteProfileSecretVariable::REQUEST_HEADERS].freeze

  include Sanitizable

  belongs_to :project
  belongs_to :dast_site

  has_many :secret_variables, class_name: 'Dast::SiteProfileSecretVariable'

  validates :excluded_urls, length: { maximum: 25 }
  validates :auth_url, addressable_url: true, length: { maximum: 1024 }, allow_nil: true
  validates :auth_username_field, :auth_password_field, :auth_username, :auth_submit_field, length: { maximum: 255 }
  validates :scan_file_path, length: { maximum: 1024 }
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }, presence: true
  validates :project_id, :dast_site_id, presence: true

  validate :dast_site_project_id_fk
  validate :excluded_urls_contains_valid_urls
  validate :excluded_urls_contains_valid_strings
  validate :scan_file_path_contains_valid_url

  scope :with_dast_site_and_validation, -> { includes(dast_site: :dast_site_validation) }
  scope :with_name, -> (name) { where(name: name) }
  scope :with_project_id, -> (project_id) { where(project_id: project_id) }
  scope :with_project, -> { includes(:project) }

  before_save :ensure_scan_file_path
  after_destroy :cleanup_dast_site

  enum target_type: { website: 0, api: 1 }

  enum scan_method: { site: 0, openapi: 1, har: 2, postman: 3, graphql: 4 }, _prefix: true

  delegate :dast_site_validation, to: :dast_site, allow_nil: true

  SCAN_METHOD_VARIABLE_MAP = { openapi: 'DAST_API_OPENAPI',
                               har: 'DAST_API_HAR',
                               postman: 'DAST_API_POSTMAN_COLLECTION',
                               graphql: 'DAST_API_GRAPHQL' }.with_indifferent_access.freeze

  sanitizes! :name, :scan_file_path

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
        variables.append(key: 'DAST_EXCLUDE_URLS', value: excluded_urls.join(',')) unless excluded_urls.empty?
      else
        variables.concat(dast_api_config(url))
      end

      if auth_enabled
        variables.append(key: 'DAST_AUTH_URL', value: auth_url)
        variables.append(key: 'DAST_USERNAME', value: auth_username)
        variables.append(key: 'DAST_USERNAME_FIELD', value: auth_username_field)
        variables.append(key: 'DAST_PASSWORD_FIELD', value: auth_password_field)
        variables.append(key: 'DAST_SUBMIT_FIELD', value: auth_submit_field)
        variables.append(key: 'DAST_API_HTTP_USERNAME', value: auth_username)
      end
    end

    collection.compact
  end

  def secret_ci_variables(user)
    collection = ::Gitlab::Ci::Variables::Collection.new

    return collection unless Ability.allowed?(user, :read_on_demand_dast_scan, self)

    collection.concat(secret_variables).tap do |variables|
      API_SECRETS_KEYS.each do |key|
        if variables[key]
          variables.append(api_secret_variable(key, variables[key]))
        end
      end
    end
  end

  def status
    return DastSiteValidation::NONE_STATE unless dast_site_validation

    dast_site_validation.state
  end

  def referenced_in_security_policies
    return [] unless project.all_security_orchestration_policy_configurations.present?

    project
      .all_security_orchestration_policy_configurations
      .map { |configuration| configuration.active_policy_names_with_dast_site_profile(name) }
      .inject(&:merge)
      .to_a
  end

  def scan_file_path_or_dast_site_url
    return dast_site.url if api? && scan_file_path.blank?

    scan_file_path
  end

  def validation_started_at
    return unless dast_site_validation

    dast_site_validation.validation_started_at
  end

  private

  def cleanup_dast_site
    dast_site.destroy if dast_site.dast_site_profiles.empty?
  end

  def dast_site_project_id_fk
    unless project_id == dast_site&.project_id
      errors.add(:project_id, _('does not match dast_site.project'))
    end
  end

  def excluded_urls_contains_valid_urls
    validate_excluded_urls_with(_("contains invalid URLs (%{urls})")) do |excluded_url|
      !Gitlab::UrlSanitizer.valid?(excluded_url)
    end
  end

  def excluded_urls_contains_valid_strings
    validate_excluded_urls_with(_("contains URLs that exceed the 1024 character limit (%{urls})")) do |excluded_url|
      excluded_url.length > 1024
    end
  end

  def validate_excluded_urls_with(message, &block)
    return if excluded_urls.blank?

    invalid = excluded_urls.select(&block)

    return if invalid.empty?

    errors.add(:excluded_urls, message % { urls: invalid.join(', ') })
  end

  def ensure_scan_file_path
    if api? && scan_file_path.blank?
      self.scan_file_path = dast_site.url
    elsif website? && scan_file_path.present?
      self.scan_file_path = nil
    end
  end

  def scan_file_path_contains_valid_url
    return if scan_file_path.blank? || scan_method_graphql? || Gitlab::UrlSanitizer.valid?(scan_file_path)

    errors.add(:base, _('%{key} is not a valid URL.') % { key: scan_file_path_error_message })
  end

  def scan_file_path_error_message
    case scan_method
    when 'openapi'
      _('OpenAPI Specification file URL')
    when 'har'
      _('HAR file URL')
    when 'postman'
      _('Postman collection file URL')
    end
  end

  def dast_api_config(url)
    [].tap do |dast_api_config|
      api_specification = scan_file_path.presence || url

      dast_api_config.append(key: 'DAST_API_EXCLUDE_URLS', value: excluded_urls.join(',')) unless excluded_urls.empty?

      dast_api_config.append(key: SCAN_METHOD_VARIABLE_MAP[scan_method], value: api_specification)
      dast_api_config.append(key: 'DAST_API_TARGET_URL', value: url) if scan_method_graphql?
    end
  end

  def api_secret_variable(key, value)
    secret = value.to_runner_variable
    secret[:key] = Dast::SiteProfileSecretVariable::API_SCAN_VARIABLES_MAP[key]
    secret
  end
end
