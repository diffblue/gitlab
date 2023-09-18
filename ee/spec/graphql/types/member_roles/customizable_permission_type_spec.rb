# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomizablePermission'], feature_category: :system_access do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('CustomizablePermission') }

  it 'has the expected fields' do
    expected_fields = %w[availableFor description requirement name value]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
