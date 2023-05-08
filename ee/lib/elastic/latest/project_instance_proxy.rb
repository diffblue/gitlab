# frozen_string_literal: true

module Elastic
  module Latest
    class ProjectInstanceProxy < ApplicationInstanceProxy
      TRACKED_FEATURE_SETTINGS = %w(
        issues_access_level
        merge_requests_access_level
        snippets_access_level
        wiki_access_level
        repository_access_level
      ).freeze

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributes
        # https://gitlab.com/gitlab-org/gitlab/issues/349
        data = {}

        [
          :id,
          :name,
          :path,
          :description,
          :namespace_id,
          :created_at,
          :updated_at,
          :archived,
          :visibility_level,
          :last_activity_at,
          :name_with_namespace,
          :path_with_namespace
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        # Set it as a parent in our `project => child` JOIN field
        data['join_field'] = es_type

        # ES6 is now single-type per index, so we implement our own typing
        data['type'] = 'project'

        # Schema version. The format is Date.today.strftime('%y_%m')
        # Please update if you're changing the schema of the document
        data['schema_version'] = 23_01

        data['traversal_ids'] = target.elastic_namespace_ancestry

        TRACKED_FEATURE_SETTINGS.each do |feature|
          data[feature] = if target.project_feature.present?
                            target.project_feature.public_send(feature) # rubocop:disable GitlabSecurity/PublicSend
                          else
                            logger.warn(message: 'Project is missing ProjectFeature', id: target.id)
                            ProjectFeature::PRIVATE
                          end
        end

        data
      end
    end
  end
end
