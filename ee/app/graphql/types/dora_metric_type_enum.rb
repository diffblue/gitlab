# frozen_string_literal: true

module Types
  class DoraMetricTypeEnum < BaseEnum
    graphql_name 'DoraMetricType'
    description 'All supported DORA metric types.'

    value 'DEPLOYMENT_FREQUENCY', description: 'Deployment frequency.', value: ::Dora::DeploymentFrequencyMetric::METRIC_NAME
    value 'LEAD_TIME_FOR_CHANGES', description: 'Lead time for changes.', value: ::Dora::LeadTimeForChangesMetric::METRIC_NAME
    value 'TIME_TO_RESTORE_SERVICE', description: 'Time to restore service.', value: ::Dora::TimeToRestoreServiceMetric::METRIC_NAME
    value 'CHANGE_FAILURE_RATE', description: 'Change failure rate.', value: ::Dora::ChangeFailureRateMetric::METRIC_NAME
  end
end
