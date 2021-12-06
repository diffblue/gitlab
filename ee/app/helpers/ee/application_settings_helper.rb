# frozen_string_literal: true

module EE
  module ApplicationSettingsHelper
    extend ::Gitlab::Utils::Override

    def pseudonymizer_enabled_help_text
      _("Enable Pseudonymizer data collection")
    end

    def pseudonymizer_description_text
      _("GitLab runs a background job to export pseudonymized CSVs of the GitLab database. The CSV files are then uploaded to your configured object storage directory.")
    end

    def pseudonymizer_disabled_description_text
      _("Pseudonymized data collection is disabled. When enabled, GitLab runs a background job to export pseudonymized CSVs of the GitLab database. The CSV files are then uploaded to your configured object storage directory.")
    end

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
        :enforce_pat_expiration,
        :enforce_ssh_key_expiration,
        :geo_node_allowed_ips,
        :geo_status_timeout,
        :help_text,
        :lock_memberships_to_ldap,
        :max_personal_access_token_lifetime,
        :max_ssh_key_lifetime,
        :pseudonymizer_enabled,
        :repository_size_limit,
        :secret_detection_token_revocation_enabled,
        :secret_detection_token_revocation_url,
        :secret_detection_token_revocation_token,
        :secret_detection_revocation_token_types_url,
        :shared_runners_minutes,
        :slack_app_enabled,
        :slack_app_id,
        :slack_app_secret,
        :slack_app_verification_token,
        :throttle_incident_management_notification_enabled,
        :throttle_incident_management_notification_per_period,
        :throttle_incident_management_notification_period_in_seconds
      ]
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
      repository_mirror_attributes + merge_request_appovers_rules_attributes +
       %i[
        email_additional_text
        file_template_project_id
        git_two_factor_session_expiry
        group_owners_can_manage_default_branch_protection
        default_project_deletion_protection
        delayed_project_deletion
        deletion_adjourned_period
        updating_name_disabled_for_users
        npm_package_requests_forwarding
        pypi_package_requests_forwarding
        maintenance_mode
        maintenance_mode_message
      ]
    end

    def self.merge_request_appovers_rules_attributes
      %i[
        disable_overriding_approvers_per_merge_request
        prevent_merge_requests_author_approval
        prevent_merge_requests_committers_approval
      ]
    end
  end
end
