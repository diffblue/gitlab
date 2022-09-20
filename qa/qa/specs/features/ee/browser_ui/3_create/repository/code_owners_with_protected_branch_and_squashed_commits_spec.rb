# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Setup an MR with codeowners file', product_group: :source_code do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.initialize_with_readme = true
        end
      end

      let!(:target) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = project.default_branch
          commit.add_files([{ file_path: '.gitlab/CODEOWNERS', content: '* @root' }])
        end
      end

      let!(:source) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = 'codeowners_test'
          commit.start_branch = project.default_branch
          commit.add_files([{ file_path: 'test1.txt', content: '1' }])
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = 'codeowners_test'
          commit.add_files([{ file_path: 'test2.txt', content: '2' }])
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'creates a merge request with codeowners file and squashing commits enabled', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347672' do
        # The default branch is already protected, and we can't update a protected branch via the API (yet)
        # so we unprotect it first and then protect it again with the desired parameters
        Resource::ProtectedBranch.unprotect_via_api! do |branch|
          branch.project = project
          branch.branch_name = project.default_branch
        end

        Resource::ProtectedBranch.fabricate_via_api! do |branch|
          branch.project = project
          branch.new_branch = false
          branch.branch_name = project.default_branch
          branch.allowed_to_push = { roles: Resource::ProtectedBranch::Roles::NO_ONE }
          branch.allowed_to_merge = { roles: Resource::ProtectedBranch::Roles::MAINTAINERS }
          branch.require_code_owner_approval = true
        end

        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.no_preparation = true
          mr.project = project
          mr.source_branch = source.branch
          mr.target_branch = target.branch
          mr.title = 'merging two commits'
        end.visit!

        Page::MergeRequest::Show.perform do |mr|
          mr.mark_to_squash
          mr.merge!

          expect(mr).to be_merged
        end
      end
    end
  end
end
