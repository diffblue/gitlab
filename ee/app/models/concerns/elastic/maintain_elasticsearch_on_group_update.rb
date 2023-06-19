# frozen_string_literal: true

module Elastic
  module MaintainElasticsearchOnGroupUpdate
    extend ActiveSupport::Concern

    included do
      after_create_commit :sync_group_wiki_in_elastic, if: :should_index_group_wiki?
      after_update_commit :maintain_group_wiki_permissions_in_elastic, if: :should_index_group_wiki?
      after_destroy_commit :remove_group_wiki_in_elastic, if: :should_index_group_wiki?
    end

    private

    def maintain_group_wiki_permissions_in_elastic
      sync_group_wiki_in_elastic if visibility_level_previously_changed?
    end

    def remove_group_wiki_in_elastic
      ::Search::Wiki::ElasticDeleteGroupWikiWorker.perform_async(id)
    end

    def sync_group_wiki_in_elastic
      ElasticWikiIndexerWorker.perform_async(id, self.class.name, force: true)
    end

    def should_index_group_wiki?
      Feature.enabled?(:maintain_group_wiki_index, self) && use_elasticsearch? && ::Wiki.use_separate_indices?
    end
  end
end
