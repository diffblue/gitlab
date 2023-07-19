# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchRule'], feature_category: :source_code_management do
  include GraphqlHelpers

  subject { described_class }

  let_it_be(:fields) { %i[approval_rules external_status_checks] }

  it { is_expected.to have_graphql_fields(fields).at_least }
end
