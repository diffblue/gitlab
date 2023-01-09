# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Merge request > User sees closing issues message', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:issue_1) { create(:issue, project: project) }
  let(:issue_2) { create(:issue, project: project) }
  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      source_project: project,
      description: merge_request_description
    )
  end

  before do
    project.add_developer(user)
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
    wait_for_requests
  end

  context 'approvals are enabled while closing issues', :js do
    let(:project) { create(:project, :public, :repository, approvals_before_merge: 1) }
    let(:merge_request_description) { "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}" }

    it 'displays closing issue message exactly one time' do
      expect(page).to have_content("Closes issues #{issue_1.to_reference} and #{issue_2.to_reference}", count: 1)
    end
  end
end
