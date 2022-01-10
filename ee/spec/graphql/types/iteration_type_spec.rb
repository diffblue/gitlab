# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Iteration'] do
  it { expect(described_class.graphql_name).to eq('Iteration') }

  it { expect(described_class).to require_graphql_authorizations(:read_iteration) }

  it 'has the expected fields' do
    expected_fields = %w[
      id iid sequence title description state web_path web_url scoped_path scoped_url
      due_date start_date created_at updated_at report iteration_cadence
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end
