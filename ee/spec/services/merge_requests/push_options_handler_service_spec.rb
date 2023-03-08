# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PushOptionsHandlerService, feature_category: :source_code_management do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user1) { create(:user, developer_projects: [project]) }
  let_it_be(:user2) { create(:user, developer_projects: [project]) }
  let_it_be(:user3) { create(:user, developer_projects: [project]) }
  let_it_be(:forked_project) { fork_project(project, user1, repository: true) }

  let(:service) { described_class.new(project: project, current_user: user1, changes: changes, push_options: push_options) }
  let(:source_branch) { 'fix' }
  let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:error_mr_required) { "A merge_request.create push option is required to create a merge request for branch #{source_branch}" }

  before do
    stub_licensed_features(multiple_merge_request_assignees: true)
  end

  describe '`assign` push option' do
    let(:assigned) { { user2.id => 1, user3.id => 1 } }
    let(:unassigned) { nil }
    let(:push_options) { { assign: assigned, unassign: unassigned } }

    it_behaves_like 'with a new branch', 2
    it_behaves_like 'with an existing branch but no open MR', 2
    it_behaves_like 'with an existing branch that has a merge request open', 2
  end

  describe '`unassign` push option' do
    let(:assigned) { { user2.id => 1, user3.id => 1 } }
    let(:unassigned) { { user1.id => 1, user3.id => 1 } }
    let(:push_options) { { assign: assigned, unassign: unassigned } }

    it_behaves_like 'with a new branch', 1
    it_behaves_like 'with an existing branch but no open MR', 1
    it_behaves_like 'with an existing branch that has a merge request open', 1
  end
end
