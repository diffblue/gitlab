# frozen_string_literal: true

module Types
  class DoraMetricTypeEnum < BaseEnum
    graphql_name 'DoraMetricType'
    description 'All supported DORA metric types.'

    value 'DEPLOYMENT_FREQUENCY', description: 'Deployment frequency.', value: Dora::DailyMetrics::METRIC_DEPLOYMENT_FREQUENCY
    value 'LEAD_TIME_FOR_CHANGES', description: 'Lead time for changes.', value: Dora::DailyMetrics::METRIC_LEAD_TIME_FOR_CHANGES
    value 'TIME_TO_RESTORE_SERVICE', description: 'Time to restore service.', value: Dora::DailyMetrics::METRIC_TIME_TO_RESTORE_SERVICE
    value 'CHANGE_FAILURE_RATE', description: 'Change failure rate.', value: Dora::DailyMetrics::METRIC_CHANGE_FAILURE_RATE
  end
end
