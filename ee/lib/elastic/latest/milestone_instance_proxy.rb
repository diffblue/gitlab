# frozen_string_literal: true

module Elastic
  module Latest
    class MilestoneInstanceProxy < ApplicationInstanceProxy
      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [:id, :iid, :title, :description, :project_id, :created_at, :updated_at].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data['visibility_level'] = target.project.visibility_level
        data['merge_requests_access_level'] = safely_read_project_feature_for_elasticsearch(:merge_requests)
        data['issues_access_level'] = safely_read_project_feature_for_elasticsearch(:issues)
        data.merge(generic_attributes)
      end
    end
  end
end
