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
        if updated_attributes.include?(:visibility_level) || updated_attributes.include?(:repository_access_level)
          maintain_elasticsearch_permissions
        end

        super
      end

      override :maintain_elasticsearch_destroy
      def maintain_elasticsearch_destroy
        ElasticDeleteProjectWorker.perform_async(self.id, self.es_id)
      end

      def invalidate_elasticsearch_indexes_cache!
        ::Gitlab::CurrentSettings.invalidate_elasticsearch_indexes_cache_for_project!(self.id)
      end

      private

      def maintain_elasticsearch_permissions
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(self)
      end
    end
  end
end
