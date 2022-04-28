# frozen_string_literal: true

module Projects
  module Prometheus
    module Metrics
      class UpdateService < Metrics::BaseService
        def execute
          metric.update(params)
          metric
        end
      end
    end
  end
end
