# frozen_string_literal: true

module EE
  module ApplicationSettingsHelper
    extend ::Gitlab::Utils::Override

    override :visible_attributes
    def visible_attributes
      super + [
        :allow_group_owners_to_manage_ldap,
        :automatic_purchased_storage_allocation,
        :check_namespace_plan,
        :elasticsearch_aws_access_key,
        :elasticsearch_aws_region,
        :elasticsearch_aws_secret_access_key,
        :elasticsearch_aws,
        :elasticsearch_client_request_timeout,
        :elasticsearch_indexed_field_length_limit,
        :elasticsearch_indexed_file_size_limit_kb,
        :elasticsearch_indexing,
        :elasticsearch_limit_indexing,
        :elasticsearch_max_bulk_concurrency,
        :elasticsearch_max_bulk_size_mb,
        :elasticsearch_namespace_ids,
        :elasticsearch_pause_indexing,
        :elasticsearch_project_ids,
        :elasticsearch_replicas,
        :elasticsearch_search,
        :elasticsearch_shards,
        :elasticsearch_url,
        :elasticsearch_username,
        :elasticsearch_password,
        :elasticsearch_limit_indexing,
        :elasticsearch_namespace_ids,
        :elasticsearch_project_ids,
        :elasticsearch_client_request_timeout,
        :elasticsearch_analyzers_smartcn_enabled,
        :elasticsearch_analyzers_smartcn_search,
        :elasticsearch_analyzers_kuromoji_enabled,
        :elasticsearch_analyzers_kuromoji_search,
        :enforce_namespace_storage_limit,
        :geo_node_allowed_ips,
        :geo_status_timeout,
        :help_text,
        :lock_memberships_to_ldap,
        :lock_memberships_to_saml,
        :max_personal_access_token_lifetime,
        :max_ssh_key_lifetime,
        :repository_size_limit,
        :search_max_shard_size_gb,
        :search_max_docs_denominator,
        :search_min_docs_before_rollover,
        :secret_detection_token_revocation_enabled,
        :secret_detection_token_revocation_url,
        :secret_detection_token_revocation_token,
        :secret_detection_revocation_token_types_url,
        :shared_runners_minutes,
        :throttle_incident_management_notification_enabled,
        :throttle_incident_management_notification_per_period,
        :throttle_incident_management_notification_period_in_seconds,
        :product_analytics_enabled,
        :jitsu_host,
        :jitsu_project_xid,
        :jitsu_administrator_email,
        :jitsu_administrator_password,
        :product_analytics_data_collector_host,
        :product_analytics_clickhouse_connection_string,
        :product_analytics_configurator_connection_string,
        :cube_api_base_url,
        :cube_api_key,
        :telesign_customer_xid,
        :telesign_api_key,
        :openai_api_key,
        :security_policy_global_group_approvers_enabled
      ].tap do |settings|
        next unless ::Gitlab.com?

        settings << :dashboard_limit_enabled
        settings << :dashboard_limit
        settings << :dashboard_notification_limit
        settings << :dashboard_enforcement_limit
        settings << :dashboard_limit_new_namespace_creation_enforcement_date
      end
    end

    def elasticsearch_objects_options(objects)
      objects.map { |g| { id: g.id, text: g.full_path } }
    end

    # The admin UI cannot handle so many namespaces so we just hide it. We
    # assume people doing this are using automation anyway.
    def elasticsearch_too_many_namespaces?
      ElasticsearchIndexedNamespace.count > 50
    end

    # The admin UI cannot handle so many projects so we just hide it. We
    # assume people doing this are using automation anyway.
    def elasticsearch_too_many_projects?
      ElasticsearchIndexedProject.count > 50
    end

    def elasticsearch_namespace_ids
      ElasticsearchIndexedNamespace.target_ids.join(',')
    end

    def elasticsearch_project_ids
      ElasticsearchIndexedProject.target_ids.join(',')
    end

    def self.repository_mirror_attributes
      [
        :mirror_max_capacity,
        :mirror_max_delay,
        :mirror_capacity_threshold
      ]
    end

    def self.possible_licensed_attributes
      repository_mirror_attributes +
      merge_request_appovers_rules_attributes +
      password_complexity_attributes +
      git_abuse_rate_limit_attributes +
      delayed_deletion_attributes +
       %i[
         email_additional_text
         file_template_project_id
         git_two_factor_session_expiry
         group_owners_can_manage_default_branch_protection
         default_project_deletion_protection
         disable_personal_access_tokens
         deletion_adjourned_period
         updating_name_disabled_for_users
         maven_package_requests_forwarding
         npm_package_requests_forwarding
         pypi_package_requests_forwarding
         maintenance_mode
         maintenance_mode_message
         globally_allowed_ips
       ]
    end

    def self.merge_request_appovers_rules_attributes
      %i[
        disable_overriding_approvers_per_merge_request
        prevent_merge_requests_author_approval
        prevent_merge_requests_committers_approval
      ]
    end

    def self.password_complexity_attributes
      %i[
        password_number_required
        password_symbol_required
        password_uppercase_required
        password_lowercase_required
      ]
    end

    def self.git_abuse_rate_limit_attributes
      %i[
        max_number_of_repository_downloads
        max_number_of_repository_downloads_within_time_period
        git_rate_limit_users_allowlist
        git_rate_limit_users_alertlist
        auto_ban_user_on_excessive_projects_download
      ]
    end

    def self.delayed_deletion_attributes
      # TODO: Remove in 16.0, after https://gitlab.com/gitlab-org/gitlab/-/issues/393622 is turned ON
      # We cannot add a feature flag check in this file, due to the reason mentioned in
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92218#note_1026250151
      %i[
        delayed_project_deletion
        delayed_group_deletion
      ]
    end

    override :registration_features_can_be_prompted?
    def registration_features_can_be_prompted?
      !::Gitlab::CurrentSettings.usage_ping_enabled? && !License.current.present?
    end

    override :signup_form_data
    def signup_form_data
      return super unless ::License.feature_available?(:password_complexity)

      super.merge({
        password_uppercase_required: @application_setting[:password_uppercase_required].to_s,
        password_lowercase_required: @application_setting[:password_lowercase_required].to_s,
        password_number_required: @application_setting[:password_number_required].to_s,
        password_symbol_required: @application_setting[:password_symbol_required].to_s
      })
    end

    def deletion_protection_data
      {
        deletion_adjourned_period: @application_setting[:deletion_adjourned_period],
        delayed_group_deletion: @application_setting[:delayed_group_deletion].to_s,
        delayed_project_deletion: @application_setting[:delayed_project_deletion].to_s
      }
    end

    def git_abuse_rate_limit_data
      limit = @application_setting[:max_number_of_repository_downloads].to_i
      interval = @application_setting[:max_number_of_repository_downloads_within_time_period].to_i
      allowlist = @application_setting[:git_rate_limit_users_allowlist].to_a
      alertlist = @application_setting.git_rate_limit_users_alertlist
      auto_ban_users = @application_setting[:auto_ban_user_on_excessive_projects_download].to_s

      {
        max_number_of_repository_downloads: limit,
        max_number_of_repository_downloads_within_time_period: interval,
        git_rate_limit_users_allowlist: allowlist,
        git_rate_limit_users_alertlist: alertlist,
        auto_ban_user_on_excessive_projects_download: auto_ban_users
      }
    end

    def sync_purl_types_checkboxes(form)
      ::Enums::PackageMetadata.purl_types.keys.map do |name|
        checked = @application_setting.package_metadata_purl_types_names.include?(name)
        numeric = ::Enums::PackageMetadata.purl_types[name]

        form.gitlab_ui_checkbox_component(
          :package_metadata_purl_types,
          name,
          checkbox_options: { checked: checked, multiple: true, autocomplete: 'off' },
          checked_value: numeric,
          unchecked_value: nil
        )
      end
    end
  end
end
