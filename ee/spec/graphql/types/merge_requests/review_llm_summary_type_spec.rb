# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestReviewLlmSummary'], feature_category: :code_review_workflow do
  let(:fields) do
    %i[
      user
      reviewer
      merge_request_diff_id
      provider
      content
      created_at
      updated_at
    ]
  end

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_merge_request) }
end
