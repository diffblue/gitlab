# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchProtection'] do
  subject { described_class }

  let(:fields) do
    %i[
      allow_force_push
      code_owner_approval_required
      merge_access_levels
      push_access_levels
      unprotect_access_levels
    ]
  end

  specify { is_expected.to have_graphql_fields(fields).only }
end
