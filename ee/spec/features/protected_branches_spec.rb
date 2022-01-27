# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Branches', :js do
  include ProtectedBranchHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  describe 'code owner approval' do
    describe 'when project requires code owner approval' do
      before do
        stub_licensed_features(protected_refs_for_users: true, code_owner_approval_required: true)
      end

      describe 'protect a branch form' do
        let!(:protected_branch) { create(:protected_branch, project: project) }
        let(:container) { page.find('#new_protected_branch') }
        let(:code_owner_toggle) { container.find('.js-code-owner-toggle') }
        let(:branch_input) { container.find('.js-protected-branch-select') }
        let(:allowed_to_merge_input) { container.find('.js-allowed-to-merge') }
        let(:allowed_to_push) { container.find('.js-allowed-to-push') }

        before do
          visit project_settings_repository_path(project)
        end

        def fill_in_form(branch_name)
          branch_input.click
          click_on branch_name

          allowed_to_merge_input.click
          wait_for_requests
          page.find('.dropdown.show').click_on 'No one'

          allowed_to_push.click
          wait_for_requests
          page.find('.dropdown.show').click_on 'No one'
        end

        def submit_form
          click_on 'Protect'
          wait_for_requests
        end

        it 'has code owner toggle' do
          expect(page).to have_content("Require approval from code owners")
          expect(code_owner_toggle[:class]).to include("is-checked")
        end

        it 'can create new protected branch with code owner disabled' do
          fill_in_form "with-codeowners"

          code_owner_toggle.click
          expect(code_owner_toggle[:class]).not_to include("is-checked")

          submit_form

          expect(project.protected_branches.find_by_name("with-codeowners").code_owner_approval_required).to be(false)
        end

        it 'can create new protected branch with code owner enabled' do
          fill_in_form "with-codeowners"

          expect(code_owner_toggle[:class]).to include("is-checked")

          submit_form

          expect(project.protected_branches.find_by_name("with-codeowners").code_owner_approval_required).to be(true)
        end
      end

      describe 'protect branch table' do
        context 'has a protected branch with code owner approval toggled on' do
          let!(:protected_branch) { create(:protected_branch, project: project, code_owner_approval_required: true) }

          before do
            visit project_settings_repository_path(project)
          end

          it 'shows code owner approval toggle' do
            expect(page).to have_content("Code owner approval")
          end

          it 'displays toggle on' do
            expect(page).to have_css('.js-code-owner-toggle.is-checked')
          end
        end

        context 'has a protected branch with code owner approval toggled off ' do
          let!(:protected_branch) { create(:protected_branch, project: project, code_owner_approval_required: false) }

          it 'displays toggle off' do
            visit project_settings_repository_path(project)

            page.within '.qa-protected-branches-list' do # rubocop:disable QA/SelectorUsage
              expect(page).not_to have_css('.js-code-owner-toggle.is-checked')
            end
          end
        end
      end
    end

    describe 'when project does not require code owner approval' do
      before do
        stub_licensed_features(protected_refs_for_users: true, code_owner_approval_required: false)

        visit project_settings_repository_path(project)
      end

      it 'does not have code owner approval in the form' do
        expect(page).not_to have_content("Require approval from code owners")
      end

      it 'does not have code owner approval in the table' do
        expect(page).not_to have_content("Code owner approval")
      end
    end
  end

  describe 'access control' do
    describe 'with ref permissions for users enabled' do
      before do
        stub_licensed_features(protected_refs_for_users: true)
      end

      include_examples 'protected branches > access control > EE'
    end

    describe 'with ref permissions for users disabled' do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      include_examples 'protected branches > access control > CE'

      context 'with existing access levels' do
        let(:protected_branch) { create(:protected_branch, project: project) }

        it 'shows users that can push to the branch' do
          protected_branch.push_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also push to this branch: "\
                                       "Jane")
        end

        it 'shows groups that can push to the branch' do
          protected_branch.push_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of this group can also push to "\
                                       "this branch: Team Awesome")
        end

        it 'shows users that can merge into the branch' do
          protected_branch.merge_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also merge into "\
                                       "this branch: Jane")
        end

        it 'shows groups that have can push to the branch' do
          protected_branch.merge_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)
          protected_branch.merge_access_levels.new(group: create(:group, name: 'Team B'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of these groups can also merge into "\
                                       "this branch:")
          expect(page).to have_content(/(Team Awesome|Team B) and (Team Awesome|Team B)/)
        end
      end
    end
  end

  context 'when the users for protected branches feature is on' do
    before do
      stub_licensed_features(protected_refs_for_users: true)
    end

    include_examples 'Deploy keys with protected branches' do
      let(:all_dropdown_sections) { %w(Roles Users Deploy\ Keys) }
    end
  end
end
