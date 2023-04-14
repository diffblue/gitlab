# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ApprovalRule'] do
  let(:fields) do
    %i[
      id name type approvals_required approved overridden section contains_hidden_groups source_rule
      eligible_approvers users approved_by groups section commented_by invalid allow_merge_when_invalid
    ]
  end

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_approval_rule) }
end
