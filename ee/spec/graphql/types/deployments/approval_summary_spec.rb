# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DeploymentApprovalSummary'] do
  specify { expect(described_class.graphql_name).to eq('DeploymentApprovalSummary') }

  it 'includes the expected fields' do
    expected_fields = %w[
      total_required_approvals total_pending_approval_count status rules
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
