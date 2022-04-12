# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunner'] do
  it { expect(described_class.graphql_name).to eq('CiRunner') }

  it 'includes the ee specific fields' do
    expected_fields = %w[public_projects_minutes_cost_factor private_projects_minutes_cost_factor upgrade_status]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
