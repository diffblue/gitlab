# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersAssociatingGroupMilestonesToReleasesMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { Release.with_group_milestones }

          start { Release.minimum(:author_id) }
          finish { Release.maximum(:author_id) }
        end
      end
    end
  end
end
