# frozen_string_literal: true

module Elastic
  module Latest
    class MergeRequestInstanceProxy < ApplicationInstanceProxy
      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [
          :id,
          :iid,
          :target_branch,
          :source_branch,
          :title,
          :description,
          :created_at,
          :updated_at,
          :state,
          :merge_status,
          :source_project_id,
          :target_project_id,
          :project_id, # Redundant field aliased to target_project_id makes it easier to share searching code
          :author_id
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data['visibility_level'] = target.project.visibility_level
        data['merge_requests_access_level'] = safely_read_project_feature_for_elasticsearch(:merge_requests)

        data.merge(generic_attributes)
      end

      def generic_attributes
        if Elastic::DataMigrationService.migration_has_finished?(:migrate_merge_requests_to_separate_index)
          super.except('join_field')
        else
          super
        end
      end
    end
  end
end
