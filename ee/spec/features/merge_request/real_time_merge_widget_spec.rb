# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Real-time merge widget', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let!(:merge_request) { create(:merge_request, :simple, source_project: project, author: user) }

  before do
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  context 'when MR dependency gets added' do
    let(:other_merge_request) { create(:merge_request, source_project: project, author: user) }

    let(:trigger_action) do
      MergeRequests::UpdateBlocksService
        .new(merge_request, user, {
          remove_hidden: false,
          references: [other_merge_request.to_reference(full: true)],
          update: true
        })
        .execute
    end

    let(:widget_text) { 'Merge blocked: you can only merge after the above items are resolved.' }

    before do
      stub_licensed_features(blocking_merge_requests: true)
    end

    it_behaves_like 'updates merge widget in real-time'
  end
end
