# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class EpicsDeepestRelationshipLevelMetric < GenericMetric
          value do
            ::Epic.deepest_relationship_level.to_i
          end
        end
      end
    end
  end
end
