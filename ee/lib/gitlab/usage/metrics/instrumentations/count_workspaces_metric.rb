# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountWorkspacesMetric < DatabaseMetric
          operation :count

          relation { RemoteDevelopment::Workspace } # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
