# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DeploymentDetails'] do
  it 'includes the expected fields' do
    expected_fields = %w[approvalSummary]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
