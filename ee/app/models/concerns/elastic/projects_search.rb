# frozen_string_literal: true

module Elastic
  module ProjectsSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    included do
      extend ::Gitlab::Utils::Override

      def use_elasticsearch?
        ::Gitlab::CurrentSettings.elasticsearch_indexes_project?(self)
      end

      override :maintain_elasticsearch_create
      def maintain_elasticsearch_create
        ::Elastic::ProcessInitialBookkeepingService.track!(self)
      end

      override :maintain_elasticsearch_update
      def maintain_elasticsearch_update(updated_attributes: previous_changes.keys)
        # avoid race condition if project is deleted before Elasticsearch update completes
        return if pending_delete?

        updated_attributes = updated_attributes.map(&:to_sym)
        # repository_access_level wiki_access_level are the attributes on project_feature
        # So we have to check the previous_changes on project_feature
        updated_attributes.concat(project_feature.previous_changes.keys.map(&:to_sym))

        if (updated_attributes & %i[visibility_level repository_access_level wiki_access_level archived]).any?
          maintain_elasticsearch_values
        end

        super
      end

      override :maintain_elasticsearch_destroy
      def maintain_elasticsearch_destroy
        ElasticDeleteProjectWorker.perform_async(self.id, self.es_id)
        Search::Zoekt::DeleteProjectWorker.perform_async(self.root_namespace&.id, self.id)
      end

      def invalidate_elasticsearch_indexes_cache!
        ::Gitlab::CurrentSettings.invalidate_elasticsearch_indexes_cache_for_project!(self.id)
      end

      private

      def maintain_elasticsearch_values
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(self)
      end
    end
  end
end
