# frozen_string_literal: true

module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `ApplicationSetting` model
  module ApplicationSetting
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT = 10_000
      DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL = 7
      MASK_PASSWORD = '*****'

      belongs_to :file_template_project, class_name: "Project"

      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }

      validates :mirror_max_delay,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: :mirror_max_delay_in_minutes }

      validates :mirror_max_capacity,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validates :mirror_capacity_threshold,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validate :mirror_capacity_threshold_less_than

      validates :repository_size_limit,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      validates :deletion_adjourned_period,
                presence: true,
                numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 90 }

      validates :search_max_shard_size_gb,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :search_max_docs_denominator,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :search_min_docs_before_rollover,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :elasticsearch_max_bulk_size_mb,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :elasticsearch_max_bulk_concurrency,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :elasticsearch_url,
                presence: { message: "can't be blank when indexing is enabled" },
                if: ->(setting) { setting.elasticsearch_indexing? }

      validates :elasticsearch_username, length: { maximum: 255 }
      validates :elasticsearch_password, length: { maximum: 255 }

      validate :check_elasticsearch_url_scheme, if: :elasticsearch_url_changed?

      validates :elasticsearch_aws_region,
                presence: { message: "can't be blank when using aws hosted elasticsearch" },
                if: ->(setting) { setting.elasticsearch_indexing? && setting.elasticsearch_aws? }

      validates :elasticsearch_indexed_file_size_limit_kb,
                presence: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :elasticsearch_indexed_field_length_limit,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      validates :elasticsearch_client_request_timeout,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      validates :email_additional_text,
                allow_blank: true,
                length: { maximum: EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT }

      attribute :future_subscriptions, ::Gitlab::Database::Type::IndifferentJsonb.new
      validates :future_subscriptions, json_schema: { filename: 'future_subscriptions' }

      validates :required_instance_ci_template, presence: true, allow_nil: true

      validates :geo_node_allowed_ips, length: { maximum: 255 }, presence: true
      validate :check_geo_node_allowed_ips

      validates :globally_allowed_ips, length: { maximum: 255 }, allow_blank: true
      validate :check_globally_allowed_ips

      validates :max_personal_access_token_lifetime,
                allow_blank: true,
                numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }

      validates :new_user_signups_cap,
                allow_blank: true,
                numericality: { only_integer: true, greater_than: 0 }

      validates :git_two_factor_session_expiry,
                presence: true,
                numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10080 }

      validates :max_ssh_key_lifetime,
                allow_blank: true,
                numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }

      validates :max_number_of_repository_downloads,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }

      validates :max_number_of_repository_downloads_within_time_period,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10.days.to_i }

      validates :git_rate_limit_users_allowlist,
                length: { maximum: 100, message: -> (object, data) { _("exceeds maximum length (100 usernames)") } },
                allow_nil: false,
                user_existence: true,
                if: :git_rate_limit_users_allowlist_changed?

      validates :git_rate_limit_users_alertlist,
                length: { maximum: 100, message: ->(object, data) { _("exceeds maximum length (100 user ids)") } },
                allow_nil: false,
                user_id_existence: true,
                if: :git_rate_limit_users_alertlist_changed?

      validates :delayed_project_removal,
                exclusion: { in: [true], message: -> (object, data) { _("can't be enabled when delayed group deletion is disabled") } },
                if: ->(setting) { !setting.delayed_group_deletion? }

      with_options(presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }) do
        validates :dashboard_limit
        validates :dashboard_notification_limit
        validates :dashboard_enforcement_limit
      end

      validates :dashboard_limit_enabled,
                inclusion: { in: [true, false], message: 'must be a boolean value' }

      validates :cube_api_base_url,
                addressable_url: ::ApplicationSetting::ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ allow_localhost: true }),
                presence: true,
                if: :product_analytics_enabled

      validates :product_analytics_enabled,
                presence: true,
                allow_blank: true

      validates :jitsu_host,
                addressable_url: ::ApplicationSetting::ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ allow_localhost: true }),
                presence: true,
                if: :product_analytics_enabled

      validates :jitsu_project_xid,
                presence: true,
                if: :product_analytics_enabled

      validates :jitsu_administrator_email,
                presence: true,
                devise_email: true,
                if: :product_analytics_enabled

      validates :jitsu_administrator_password,
                presence: true,
                if: :product_analytics_enabled

      validates :product_analytics_clickhouse_connection_string,
                presence: true,
                if: :product_analytics_enabled

      validates :cube_api_key,
                presence: true,
                if: :product_analytics_enabled

      validates :security_policy_global_group_approvers_enabled,
                inclusion: { in: [true, false], message: 'must be a boolean value' }

      validates :product_analytics_data_collector_host,
                addressable_url: ::ApplicationSetting::ADDRESSABLE_URL_VALIDATION_OPTIONS.merge({ allow_localhost: true }),
                presence: true,
                if: :product_analytics_enabled

      validates :package_metadata_purl_types, inclusion: { in: ::Enums::PackageMetadata.purl_types.values }

      alias_attribute :delayed_project_deletion, :delayed_project_removal

      before_save :update_lock_delayed_project_removal, if: :delayed_group_deletion_changed?
      after_commit :update_personal_access_tokens_lifetime, if: :saved_change_to_max_personal_access_token_lifetime?
      after_commit :resume_elasticsearch_indexing
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :defaults
      def defaults
        super.merge(
          allow_group_owners_to_manage_ldap: true,
          automatic_purchased_storage_allocation: false,
          custom_project_templates_group_id: nil,
          dashboard_limit_enabled: false,
          dashboard_limit: 0,
          dashboard_notification_limit: 0,
          dashboard_enforcement_limit: 0,
          dashboard_limit_new_namespace_creation_enforcement_date: nil,
          default_project_deletion_protection: false,
          deletion_adjourned_period: DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL,
          disable_personal_access_tokens: false,
          elasticsearch_aws_region: ENV['ELASTIC_REGION'] || 'us-east-1',
          elasticsearch_aws: false,
          elasticsearch_indexed_field_length_limit: 0,
          elasticsearch_indexed_file_size_limit_kb: 1024, # 1 MiB (units in KiB)
          elasticsearch_max_bulk_concurrency: 10,
          elasticsearch_max_bulk_size_bytes: 10.megabytes,
          elasticsearch_url: ENV['ELASTIC_URL'] || 'http://localhost:9200',
          elasticsearch_username: nil,
          elasticsearch_password: nil,
          elasticsearch_client_request_timeout: 0,
          elasticsearch_analyzers_smartcn_enabled: false,
          elasticsearch_analyzers_smartcn_search: false,
          elasticsearch_analyzers_kuromoji_enabled: false,
          elasticsearch_analyzers_kuromoji_search: false,
          email_additional_text: nil,
          enforce_namespace_storage_limit: false,
          future_subscriptions: [],
          geo_node_allowed_ips: '0.0.0.0/0, ::/0',
          git_two_factor_session_expiry: 15,
          globally_allowed_ips: '',
          license_usage_data_exported: false,
          lock_memberships_to_ldap: false,
          lock_memberships_to_saml: false,
          maintenance_mode: false,
          max_personal_access_token_lifetime: nil,
          max_ssh_key_lifetime: nil,
          mirror_capacity_threshold: Settings.gitlab['mirror_capacity_threshold'],
          mirror_max_capacity: Settings.gitlab['mirror_max_capacity'],
          mirror_max_delay: Settings.gitlab['mirror_max_delay'],
          repository_size_limit: 0,
          secret_detection_token_revocation_enabled: false,
          secret_detection_token_revocation_url: nil,
          secret_detection_token_revocation_token: nil,
          secret_detection_revocation_token_types_url: nil,
          slack_app_enabled: false,
          slack_app_id: nil,
          slack_app_secret: nil,
          slack_app_signing_secret: nil,
          slack_app_verification_token: nil,
          max_number_of_repository_downloads: 0,
          max_number_of_repository_downloads_within_time_period: 0,
          git_rate_limit_users_allowlist: [],
          git_rate_limit_users_alertlist: [],
          auto_ban_user_on_excessive_projects_download: false,
          product_analytics_enabled: false,
          jitsu_host: nil,
          jitsu_project_xid: nil,
          product_analytics_data_collector_host: nil,
          product_analytics_clickhouse_connection_string: nil,
          product_analytics_configurator_connection_string: nil,
          jitsu_administrator_email: nil,
          jitsu_administrator_password: nil,
          cube_api_base_url: nil,
          cube_api_key: nil
        )
      end

      override :non_production_defaults
      def non_production_defaults
        super.merge(
          search_max_shard_size_gb: 1,
          search_max_docs_denominator: 100,
          search_min_docs_before_rollover: 50
        )
      end
    end

    def elasticsearch_namespace_ids
      ElasticsearchIndexedNamespace.target_ids
    end

    def elasticsearch_project_ids
      ElasticsearchIndexedProject.target_ids
    end

    def elasticsearch_shards
      Elastic::IndexSetting.number_of_shards
    end

    def elasticsearch_replicas
      Elastic::IndexSetting.number_of_replicas
    end

    def elasticsearch_indexes_project?(project)
      return false unless elasticsearch_indexing?
      return true unless elasticsearch_limit_indexing?

      ::Gitlab::Elastic::ElasticsearchEnabledCache.fetch(:project, project.id) do
        elasticsearch_limited_project_exists?(project)
      end
    end

    def elasticsearch_indexes_namespace?(namespace)
      return false unless elasticsearch_indexing?
      return true unless elasticsearch_limit_indexing?

      ::Gitlab::Elastic::ElasticsearchEnabledCache.fetch(:namespace, namespace.id) do
        elasticsearch_limited_namespaces.exists?(namespace.id)
      end
    end

    def invalidate_elasticsearch_indexes_cache!
      ::Gitlab::Elastic::ElasticsearchEnabledCache.delete(:project)
      ::Gitlab::Elastic::ElasticsearchEnabledCache.delete(:namespace)
    end

    def invalidate_elasticsearch_indexes_cache_for_project!(project_id)
      ::Gitlab::Elastic::ElasticsearchEnabledCache.delete_record(:project, project_id)
    end

    def invalidate_elasticsearch_indexes_cache_for_namespace!(namespace_id)
      ::Gitlab::Elastic::ElasticsearchEnabledCache.delete_record(:namespace, namespace_id)
    end

    def elasticsearch_limited_projects(ignore_namespaces = false)
      return ::Project.where(id: ElasticsearchIndexedProject.select(:project_id)) if ignore_namespaces

      union = ::Gitlab::SQL::Union.new([
                                         ::Project.where(namespace_id: elasticsearch_limited_namespaces.select(:id)),
                                         ::Project.where(id: ElasticsearchIndexedProject.select(:project_id))
                                       ]).to_sql

      ::Project.from("(#{union}) projects")
    end

    def elasticsearch_limited_namespaces(ignore_descendants = false)
      namespaces = ::Namespace.where(id: ElasticsearchIndexedNamespace.select(:namespace_id))

      return namespaces if ignore_descendants

      namespaces.self_and_descendants
    end

    def should_check_namespace_plan?
      check_namespace_plan? && (Rails.env.test? || ::Gitlab.org_or_com?)
    end

    def elasticsearch_indexing
      return false unless elasticsearch_indexing_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_indexing?, :elasticsearch_indexing

    def elasticsearch_pause_indexing
      return false unless elasticsearch_pause_indexing_column_exists?

      super
    end
    alias_method :elasticsearch_pause_indexing?, :elasticsearch_pause_indexing

    def elasticsearch_search
      return false unless elasticsearch_search_column_exists?

      License.feature_available?(:elastic_search) && super
    end
    alias_method :elasticsearch_search?, :elasticsearch_search

    # Determines whether a search should use elasticsearch, taking the scope
    # (nil for global search, otherwise a namespace or project) into account
    def search_using_elasticsearch?(scope: nil)
      return false unless elasticsearch_indexing? && elasticsearch_search?
      return true unless elasticsearch_limit_indexing?

      case scope
      when Namespace
        elasticsearch_indexes_namespace?(scope)
      when Project
        elasticsearch_indexes_project?(scope)
      when Array
        scope.any? { |project| elasticsearch_indexes_project?(project) }
      else
        ::Feature.enabled?(:advanced_global_search_for_limited_indexing)
      end
    end

    def elasticsearch_url
      read_attribute(:elasticsearch_url).split(',').map do |s|
        URI.parse(s.strip)
      end
    end

    def elasticsearch_url=(values)
      cleaned = values.split(',').map { |url| url.strip.gsub(%r{/*\z}, '') }

      write_attribute(:elasticsearch_url, cleaned.join(','))
    end

    def elasticsearch_password=(value)
      return if value == MASK_PASSWORD

      super
    end

    def elasticsearch_aws_secret_access_key=(value)
      return if value == MASK_PASSWORD

      super
    end

    def elasticsearch_url_with_credentials
      elasticsearch_url.map do |uri|
        ::Gitlab::Elastic::Helper.connection_settings(uri: uri, user: elasticsearch_username, password: elasticsearch_password)
      end
    end

    def elasticsearch_config
      {
        url: elasticsearch_url_with_credentials,
        aws: elasticsearch_aws,
        aws_access_key: elasticsearch_aws_access_key,
        aws_secret_access_key: elasticsearch_aws_secret_access_key,
        aws_region: elasticsearch_aws_region,
        max_bulk_size_bytes: elasticsearch_max_bulk_size_mb.megabytes,
        max_bulk_concurrency: elasticsearch_max_bulk_concurrency,
        client_request_timeout: (elasticsearch_client_request_timeout if elasticsearch_client_request_timeout > 0)
      }.compact
    end

    def email_additional_text
      return false unless email_additional_text_column_exists?

      License.feature_available?(:email_additional_text) && super
    end

    def email_additional_text_character_limit
      EMAIL_ADDITIONAL_TEXT_CHARACTER_LIMIT
    end

    def custom_project_templates_enabled?
      License.feature_available?(:custom_project_templates)
    end

    def custom_project_templates_group_id
      custom_project_templates_enabled? && super
    end

    def available_custom_project_templates(subgroup_id = nil)
      group_id = subgroup_id || custom_project_templates_group_id

      return ::Project.none unless group_id

      ::Project.where(namespace_id: group_id)
    end

    override :instance_review_permitted?
    def instance_review_permitted?
      return false if License.current

      super
    end

    def max_personal_access_token_lifetime_from_now
      max_personal_access_token_lifetime&.days&.from_now
    end

    def max_ssh_key_lifetime_from_now
      max_ssh_key_lifetime&.days&.from_now
    end

    def compliance_frameworks=(values)
      cleaned = Array.wrap(values).reject(&:blank?).sort.uniq

      write_attribute(:compliance_frameworks, cleaned)
    end

    def should_apply_user_signup_cap?
      ::Gitlab::CurrentSettings.new_user_signups_cap.present?
    end

    override :personal_access_tokens_disabled?
    def personal_access_tokens_disabled?
      License.feature_available?(:disable_personal_access_tokens) &&
        ::Gitlab::CurrentSettings.disable_personal_access_tokens
    end

    def disable_feed_token
      personal_access_tokens_disabled? || read_attribute(:disable_feed_token)
    end
    alias_method :disable_feed_token?, :disable_feed_token

    def jitsu_administrator_password=(value)
      return if value == MASK_PASSWORD

      super
    end

    def git_rate_limit_users_alertlist
      self[:git_rate_limit_users_alertlist].presence || ::User.admins.active.pluck_primary_key
    end

    def package_metadata_purl_types_names
      ::Enums::PackageMetadata.purl_types_numerical.values_at(*package_metadata_purl_types)
    end

    def unique_project_download_limit_enabled?
      return true if max_number_of_repository_downloads.nonzero? && max_number_of_repository_downloads_within_time_period.nonzero?

      false
    end

    private

    def elasticsearch_limited_project_exists?(project)
      project_namespaces = ::Namespace.where(id: project.namespace_id)
      self_and_ancestors_namespaces = project_namespaces.self_and_ancestors.joins(:elasticsearch_indexed_namespace)

      indexed_namespaces = ::Project.where('EXISTS (?)', self_and_ancestors_namespaces)
      indexed_projects = ::Project.where('EXISTS (?)', ElasticsearchIndexedProject.where(project_id: project.id))

      ::Project
        .from("(SELECT) as projects") # SELECT from "nothing" since the EXISTS queries have all the conditions.
        .merge(indexed_namespaces.or(indexed_projects))
        .exists?
    end

    def resume_elasticsearch_indexing
      return false unless saved_changes['elasticsearch_pause_indexing'] == [true, false]

      ElasticIndexingControlWorker.perform_async
    end

    def update_personal_access_tokens_lifetime
      return unless max_personal_access_token_lifetime.present? && License.feature_available?(:personal_access_token_expiration_policy)

      ::PersonalAccessTokens::Instance::UpdateLifetimeService.new.execute
    end

    def mirror_max_delay_in_minutes
      ::Gitlab::Mirror.min_delay_upper_bound / 60
    end

    def mirror_capacity_threshold_less_than
      return unless mirror_max_capacity && mirror_capacity_threshold

      if mirror_capacity_threshold > mirror_max_capacity
        errors.add(:mirror_capacity_threshold, "Project's mirror capacity threshold can't be higher than it's maximum capacity")
      end
    end

    def elasticsearch_indexing_column_exists?
      self.class.database.cached_column_exists?(:elasticsearch_indexing)
    end

    def elasticsearch_pause_indexing_column_exists?
      self.class.database.cached_column_exists?(:elasticsearch_pause_indexing)
    end

    def elasticsearch_search_column_exists?
      self.class.database.cached_column_exists?(:elasticsearch_search)
    end

    def email_additional_text_column_exists?
      self.class.database.cached_column_exists?(:email_additional_text)
    end

    def check_geo_node_allowed_ips
      ::Gitlab::CIDR.new(geo_node_allowed_ips)
    rescue ::Gitlab::CIDR::ValidationError => e
      errors.add(:geo_node_allowed_ips, e.message)
    end

    def check_globally_allowed_ips
      ::Gitlab::CIDR.new(globally_allowed_ips)
    rescue ::Gitlab::CIDR::ValidationError => e
      errors.add(:globally_allowed_ips, e.message)
    end

    def check_elasticsearch_url_scheme
      # ElasticSearch only exposes a RESTful API, hence we need
      # to use the HTTP protocol on all URLs.
      elasticsearch_url.each do |str|
        ::Gitlab::UrlBlocker.validate!(str,
                                       schemes: %w[http https],
                                       allow_localhost: true,
                                       dns_rebind_protection: false)
      end
    rescue ::Gitlab::UrlBlocker::BlockedUrlError
      errors.add(:elasticsearch_url, "only supports valid HTTP(S) URLs.")
    end

    def update_lock_delayed_project_removal
      # This is the only way to update lock_delayed_project_removal and it is used to
      # enforce the cascading setting when delayed deletion is disabled on a instance.
      self.lock_delayed_project_removal = !self.delayed_group_deletion
    end
  end
end
