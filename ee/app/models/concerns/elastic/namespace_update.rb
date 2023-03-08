# frozen_string_literal: true

module Elastic
  module NamespaceUpdate
    extend ActiveSupport::Concern

    included do
      after_update :update_elasticsearch, if: :saved_change_to_parent_id?
    end

    def update_elasticsearch
      run_after_commit do
        Elastic::NamespaceUpdateWorker.perform_async(id) if ::Gitlab::CurrentSettings.elasticsearch_indexing?
      end
    end
  end
end
