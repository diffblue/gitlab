# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Deployment'], feature_category: :continuous_delivery do
  it 'includes the expected fields' do
    expected_fields = %w[approvalSummary pending_approval_count approvals]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
