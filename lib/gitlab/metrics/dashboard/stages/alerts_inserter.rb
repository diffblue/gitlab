# frozen_string_literal: true

require 'set'

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class AlertsInserter < BaseStage
          include ::Gitlab::Utils::StrongMemoize

          def transform!
            metrics_with_alerts
          end

          private

          def metrics_with_alerts
            strong_memoize(:metrics_with_alerts) do
              alerts = ::Projects::Prometheus::AlertsFinder
                .new(project: project, environment: params[:environment])
                .execute

              Set.new(alerts.map(&:prometheus_metric_id))
            end
          end
        end
      end
    end
  end
end
