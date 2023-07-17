# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AddOnPurchase'], feature_category: :shared do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('AddOnPurchase') }
  it { expect(described_class).to require_graphql_authorizations(:admin_add_on_purchase) }

  it 'has expected fields' do
    expected_fields = %w[id purchased_quantity assigned_quantity name]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
