# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates MR with multiple assignees', feature_category: :code_review_workflow do
  include_context 'merge request create context'

  before do
    stub_licensed_features(multiple_merge_request_assignees: true)
  end

  context 'when GraphQL assignees widget feature flag is disabled' do
    before do
      stub_feature_flags(issue_assignees_widget: false)
    end

    it_behaves_like 'multiple assignees merge request', 'creates', 'Create merge request'
  end

  context 'when GraphQL assignees widget feature flag is enabled' do
    it_behaves_like 'multiple assignees widget merge request', 'creates', 'Create merge request'
  end
end
