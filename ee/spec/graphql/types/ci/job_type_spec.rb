# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJob'], feature_category: :continuous_integration do
  it { expect(described_class.graphql_name).to eq('CiJob') }

  it 'includes the ee specific fields' do
    expected_fields = %w[
      ai_failure_analysis
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
