# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestApprovalState'] do
  let(:fields) { %i[approval_rules_overwritten rules invalid_approvers_rules suggested_approvers] }

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_merge_request) }
end
