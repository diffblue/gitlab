# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DeploymentApproval'] do
  specify { expect(described_class.graphql_name).to eq('DeploymentApproval') }

  it 'includes the expected fields' do
    expected_fields = %w[
      user status created_at updated_at comment
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
