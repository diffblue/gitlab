# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates MR with multiple reviewers', feature_category: :code_review_workflow do
  include_context 'merge request create context'

  before do
    stub_licensed_features(multiple_merge_request_reviewers: true)
  end

  it_behaves_like 'multiple reviewers merge request', 'creates', 'Create merge request'
end
