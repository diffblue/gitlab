# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunnerManager'], feature_category: :runner_fleet do
  it { expect(described_class.graphql_name).to eq('CiRunnerManager') }

  it 'includes the ee specific fields' do
    expected_fields = %w[upgrade_status]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
