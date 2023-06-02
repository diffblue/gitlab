# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::DoraMetricTypeEnum, feature_category: :dora_metrics do
  it 'includes a value for each DORA metric type' do
    expect(described_class.values).to match(
      'DEPLOYMENT_FREQUENCY' => have_attributes(value: 'deployment_frequency'),
      'LEAD_TIME_FOR_CHANGES' => have_attributes(value: 'lead_time_for_changes'),
      'TIME_TO_RESTORE_SERVICE' => have_attributes(value: 'time_to_restore_service'),
      'CHANGE_FAILURE_RATE' => have_attributes(value: 'change_failure_rate')
    )
  end
end
