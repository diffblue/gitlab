# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RootStorageStatistics'], feature_category: :consumables_cost_management do
  it 'includes the EE specific fields' do
    expect(described_class).to include_graphql_fields(:cost_factored_storage_size)
  end
end
