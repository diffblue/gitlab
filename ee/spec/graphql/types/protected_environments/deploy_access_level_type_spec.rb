# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProtectedEnvironmentDeployAccessLevel'] do
  specify { expect(described_class.graphql_name).to eq('ProtectedEnvironmentDeployAccessLevel') }

  it 'includes the expected fields' do
    expected_fields = %w[
      accessLevel group user
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
