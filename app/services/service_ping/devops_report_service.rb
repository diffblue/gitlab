# frozen_string_literal: true

module ServicePing
  class DevopsReportService
    def initialize(data)
      @data = data
    end

    def execute
      metrics = @data['conv_index'] || @data['dev_ops_score'] # leaving dev_ops_score here, as the data comes from the gitlab-version-com

      return unless metrics.except('usage_data_id').present?

      DevOpsReport::Metric.create!(
        metrics.slice(*DevOpsReport::Metric::METRICS)
      )
    end
  end
end
