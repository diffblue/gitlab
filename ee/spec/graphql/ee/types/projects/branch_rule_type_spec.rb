# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchRule'] do
  include GraphqlHelpers

  subject { described_class }

  let_it_be(:fields) do
    %i[
      name
      is_default
      branch_protection
      approval_rules
      created_at
      updated_at
    ]
  end

  it { is_expected.to require_graphql_authorizations(:read_protected_branch) }

  it { is_expected.to have_graphql_fields(fields).only }
end
