# frozen_string_literal: true

module EE
  module Ci
    module Queue
      module PendingBuildsStrategy
        extend ActiveSupport::Concern

        def enforce_minutes_limit(relation)
          relation.with_ci_minutes_available
        end
      end
    end
  end
end
