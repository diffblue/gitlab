# frozen_string_literal: true

module Epics
  module MetadataCacheUpdate
    extend ActiveSupport::Concern

    included do
      after_commit :update_cached_metadata
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def register_epic_id_for_cache_update(epic_id)
      @epic_ids_to_update_cache ||= Set.new
      @epic_ids_to_update_cache << epic_id
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def update_cached_metadata
      return unless @epic_ids_to_update_cache.present?

      @epic_ids_to_update_cache.each do |epic_id|
        ::Epics::UpdateCachedMetadataWorker.perform_async([epic_id])
      end

      @epic_ids_to_update_cache = nil
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
