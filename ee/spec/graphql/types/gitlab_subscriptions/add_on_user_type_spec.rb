# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AddOnUser'], feature_category: :shared do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('AddOnUser') }
  it { expect(described_class).to require_graphql_authorizations(:read_user) }

  it 'has expected fields' do
    add_on_user_fields = %w[
      addOnAssignments
    ]

    generic_user_fields = %w[
      id
      name
      username
    ]

    expect(described_class).to include_graphql_fields(*add_on_user_fields)
    expect(described_class).to include_graphql_fields(*generic_user_fields)
  end
end
