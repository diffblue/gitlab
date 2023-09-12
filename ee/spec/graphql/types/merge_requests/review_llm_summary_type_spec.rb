# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestReviewLlmSummary'], feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:fields) do
    %i[
      user
      reviewer
      merge_request_diff_id
      provider
      content
      content_html
      created_at
      updated_at
    ]
  end

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  describe 'fields' do
    let(:object) { instance_double(MergeRequest::ReviewLlmSummary) }
    let(:current_user) { instance_double(User) }

    before do
      allow(described_class).to receive(:authorized?).and_return(true)
    end

    describe '#content_html' do
      it 'calls MergeRequest::ReviewLlmSummary#content_html(current_user)' do
        allow(object).to receive(:content_html)
        resolve_field(:content_html, object, current_user: current_user)

        expect(object).to have_received(:content_html)
      end
    end
  end
end
