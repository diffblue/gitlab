# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::DoraMetricBucketingIntervalEnum, feature_category: :dora_metrics do
  it 'includes a value for each DORA bucketing interval type' do
    expect(described_class.values).to match(
      'ALL' => have_attributes(value: 'all'),
      'MONTHLY' => have_attributes(value: 'monthly'),
      'DAILY' => have_attributes(value: 'daily')
    )
  end
end
