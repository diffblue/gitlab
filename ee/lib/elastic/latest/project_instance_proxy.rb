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

        if ::Elastic::DataMigrationService.migration_has_finished?(:add_schema_version_to_main_index_mapping)
          # Schema version. The format is Date.today.strftime('%y_%m')
          # Please update if you're changing the schema of the document
          data['schema_version'] = 23_01
        end

        if ::Elastic::DataMigrationService.migration_has_finished?(:add_traversal_ids_to_original_index_mapping)
          data['traversal_ids'] = target.elastic_namespace_ancestry
        end

        # Somehow projects are being created and sent for indexing without an associated project_feature
        # https://gitlab.com/gitlab-org/gitlab/-/issues/232654
        # When this happens, log the errors to help with debugging, and raise the error to prevent indexing bad data
        TRACKED_FEATURE_SETTINGS.each do |feature|
          data[feature] = target.project_feature.public_send(feature) # rubocop:disable GitlabSecurity/PublicSend
        rescue NoMethodError => e
          # Sentry is not receiving the extra fields provided so adding an additional logging statement
          target.logger.debug(message: e.message, project_id: target.id, feature: feature)
          Gitlab::ErrorTracking.track_and_raise_exception(e, project_id: target.id, feature: feature)
        end

        data
      end
    end
  end
end
