# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchRule'] do
  include GraphqlHelpers

  subject { described_class }

  let_it_be(:fields) do
    %i[
      approval_rules
    ]
  end

  it { is_expected.to have_graphql_fields(fields).at_least }
end
