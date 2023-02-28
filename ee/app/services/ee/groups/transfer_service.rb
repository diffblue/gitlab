# frozen_string_literal: true

module EE
  module Groups
    module TransferService
      extend ::Gitlab::Utils::Override

      # TODO: Remove this method and lost_groups as well as
      # Epic#nullify_lost_group_parents and Epic#schedule_parent_cache_update when
      # `child_epics_from_different_hierarchies` feature flag is removed:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/382719
      def update_group_attributes
        ::Epic.nullify_lost_group_parents(group.self_and_descendants, lost_groups) unless cross_group_epics_enabled?

        super
      end

      override :ensure_allowed_transfer
      def ensure_allowed_transfer
        super

        raise_transfer_error(:saml_provider_or_scim_token_present) if saml_provider_or_scim_token_present?
      end

      override :localized_error_messages
      def localized_error_messages
        { saml_provider_or_scim_token_present:
          s_('TransferGroup|SAML Provider or SCIM Token is configured for this group.') }
          .merge(super).freeze
      end

      private

      def saml_provider_or_scim_token_present?
        group.saml_provider.present? || group.scim_oauth_access_token.present?
      end

      override :post_update_hooks
      def post_update_hooks(updated_project_ids, old_root_ancestor_id)
        super

        update_elasticsearch_hooks
      end

      def update_project_settings(updated_project_ids)
        ::ProjectSetting.for_projects(updated_project_ids).update_all(legacy_open_source_license_available: false)
      end

      def lost_groups
        ancestors = group.ancestors

        if ancestors.include?(new_parent_group)
          group.ancestors_upto(new_parent_group)
        else
          ancestors
        end
      end

      def update_elasticsearch_hooks
        # When a group is moved to a new group, there is no way to know whether the group was using Elasticsearch
        # before the transfer. If Elasticsearch limit indexing is enabled, the group and each project has the ES cache
        # invalidated. Reindex all projects and associated data to make sure the namespace_ancestry field gets
        # updated in each document.
        group.invalidate_elasticsearch_indexes_cache! if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

        ::Project.id_in(group.all_projects.select(:id)).find_each do |project|
          project.invalidate_elasticsearch_indexes_cache! if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?
          ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project) if project.maintaining_elasticsearch?
        end
      end

      def cross_group_epics_enabled?
        ::Feature.enabled?(:child_epics_from_different_hierarchies, group) &&
          ::Feature.enabled?(:child_epics_from_different_hierarchies, new_parent_group)
      end
    end
  end
end
