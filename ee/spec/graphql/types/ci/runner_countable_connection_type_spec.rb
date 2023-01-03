# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerCountableConnectionType, feature_category: :runner_fleet do
  it 'includes the ee specific fields' do
    expected_fields = %w[jobs_statistics]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
