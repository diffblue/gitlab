# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ApprovalProjectRule'], feature_category: :source_code_management do
  subject { described_class }

  let_it_be(:fields) { %i[id name type approvals_required eligible_approvers] }

  it { is_expected.to require_graphql_authorizations(:read_approval_rule) }

  it { is_expected.to have_graphql_fields(fields).only }
end
