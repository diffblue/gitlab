# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EpicListMetadata'] do
  specify { expect(described_class.graphql_name).to eq('EpicListMetadata') }

  it 'has specific fields' do
    expected_fields = %w[epics_count total_weight]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
