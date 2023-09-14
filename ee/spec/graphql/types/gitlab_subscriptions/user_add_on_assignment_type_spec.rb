# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['UserAddOnAssignment'], feature_category: :shared do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('UserAddOnAssignment') }
  it { expect(described_class).to require_graphql_authorizations(:admin_add_on_purchase) }

  it 'has expected fields' do
    expect(described_class).to include_graphql_fields('addOnPurchase')
  end
end
