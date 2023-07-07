# frozen_string_literal: true

module Elastic
  module MaintainElasticsearchOnGroupUpdate
    extend ActiveSupport::Concern

    included do
      after_create_commit :maintain_group_associations_on_create
      after_update_commit :maintain_group_associations_on_update
      after_destroy_commit :maintain_group_associations_on_destroy
    end

    private

    def maintain_group_associations_on_create
      sync_group_wiki_in_elastic if should_index_group_wiki?
    end

    def maintain_group_associations_on_update
      return unless visibility_level_previously_changed?

      sync_group_wiki_in_elastic if should_index_group_wiki?
      maintain_indexed_associations
    end

    def maintain_group_associations_on_destroy
      delete_group_wiki_in_elastic if should_index_group_wiki?
      delete_group_associations
    end

    def sync_group_wiki_in_elastic
      ElasticWikiIndexerWorker.perform_async(id, self.class.name, force: true)
    end

    def delete_group_wiki_in_elastic
      ::Search::Wiki::ElasticDeleteGroupWikiWorker.perform_async(id)
    end

    def maintain_indexed_associations
      Elastic::ProcessBookkeepingService.maintain_indexed_group_associations!(self)
    end

    def delete_group_associations
      Search::ElasticGroupAssociationDeletionWorker.perform_async(id, root_ancestor.id)
    end

    def should_index_group_wiki?
      use_elasticsearch? && ::Wiki.use_separate_indices?
    end
  end
end
