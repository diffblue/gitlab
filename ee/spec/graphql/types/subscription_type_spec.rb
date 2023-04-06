# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Subscription'], feature_category: :shared do
  it 'has the expected fields' do
    expected_fields = %i[
      issuable_weight_updated
      issuable_iteration_updated
      issuable_health_status_updated
      issuable_epic_updated
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
