# frozen_string_literal: true

module Zoekt
  module SearchableRepository
    extend ActiveSupport::Concern

    included do
      def use_zoekt?
        project&.use_zoekt?
      end

      def update_zoekt_index!
        ::Gitlab::Search::Zoekt::Client.index(project)
      end

      def async_update_zoekt_index
        ::Zoekt::IndexerWorker.perform_async(project.id)
      end
    end
  end
end
