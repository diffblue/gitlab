# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Merge Requests > User edits a merge request', feature_category: :code_review_workflow do
  let(:user) { create(:user) }

  before do
    stub_licensed_features(licensed_features)
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when the merge request has matching code owners', :js do
    let(:licensed_features) do
      { code_owners: true, code_owner_approval_required: true }
    end

    let(:project) do
      create(:project, :custom_repo, files: { 'docs/CODEOWNERS' => "[Backend]\n*.rb @ruby-owner\n*.js @js-owner" })
    end

    let(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        target_project: project,
        target_branch: 'master',
        source_branch: 'feature'
      )
    end

    let(:ruby_owner) { create(:user, username: 'ruby-owner') }

    before do
      project.add_developer(ruby_owner)
      project.repository.create_file(
        user, 'ruby.rb', '# a ruby file', message: 'Add a ruby file', branch_name: 'feature'
      )

      create(:protected_branch,
        name: 'master',
        code_owner_approval_required: true,
        project: project)

      # To make sure the rules are created for the merge request, the services
      # that do that aren't triggered from factories
      MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
    end

    it 'shows the matching code owner rules' do
      visit(edit_project_merge_request_path(project, merge_request))

      expect(page).to have_content('*.rb')
      expect(page).to have_content('Backend')
      expect(page).to have_link(href: user_path(ruby_owner))
    end
  end
end
