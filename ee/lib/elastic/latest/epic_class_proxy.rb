# frozen_string_literal: true

module Elastic
  module Latest
    class EpicClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        raise NotImplementedError
      end

      def preload_indexing_data(relation)
        # rubocop: disable CodeReuse/ActiveRecord
        relation.includes(
          :author,
          :labels,
          :group,
          :start_date_sourcing_epic,
          :due_date_sourcing_epic,
          :start_date_sourcing_milestone,
          :due_date_sourcing_milestone
        )
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
