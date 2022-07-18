# frozen_string_literal: true

module EE
  module Groups
    module TransferService
      extend ::Gitlab::Utils::Override

      def update_group_attributes
        ::Epic.nullify_lost_group_parents(group.self_and_descendants, lost_groups)

        super
      end

      private

      override :post_update_hooks
      def post_update_hooks(updated_project_ids)
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
    end
  end
end
