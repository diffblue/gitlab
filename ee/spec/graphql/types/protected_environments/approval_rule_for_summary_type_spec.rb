# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProtectedEnvironmentApprovalRuleForSummary'] do
  specify { expect(described_class.graphql_name).to eq('ProtectedEnvironmentApprovalRuleForSummary') }

  it 'includes the expected fields' do
    expected_fields = %w[
      approved_count pending_approval_count required_approvals status approvals
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
