# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees approval widget', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    sign_in(user)
  end

  context 'when merge when threads resolved is active' do
    let(:project) do
      create(:project, :repository,
        approvals_before_merge: 1,
        only_allow_merge_if_all_discussions_are_resolved: true)
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    # TODO: https://gitlab.com/gitlab-org/gitlab/issues/9430
    xit 'does not show checking ability text' do
      expect(find('.js-mr-approvals')).not_to have_text('Checking if merge request can be merged')
      expect(find('.js-mr-approvals')).to have_selector('.approvals-body')
    end
  end

  context 'when rules are enabled' do
    context 'merge request approvers enabled' do
      let(:project) { create(:project, :public, :repository, approvals_before_merge: 3) }

      before do
        stub_licensed_features(merge_request_approvers: true)

        visit project_merge_request_path(project, merge_request)
      end

      it 'the renders the number of required approvals' do
        wait_for_requests

        expect(page).to have_content('Requires 3 approvals from eligible users.')
      end
    end

    context 'multiple approval rules enabled' do
      let(:members) { create_list(:user, 2) }

      let!(:rule) do
        create(:approval_merge_request_rule,
               merge_request: merge_request,
               users: members,
               approvals_required: 1)
      end

      before do
        stub_licensed_features(multiple_approval_rules: true)

        members.each { |user| project.add_developer(user) }
      end

      it 'shows the approval rule' do
        visit project_merge_request_path(project, merge_request)

        wait_for_requests
        expect(page).to have_content("Requires 1 approval from #{rule.name}")

        find('[data-testid="widget-toggle"]').click
        wait_for_requests

        within('.mr-widget-workflow table') do
          expect(page).to have_content(rule.name)
        end
      end

      context 'for code owner rules' do
        let(:code_owners) { create_list(:user, 2) }

        let!(:code_owner_rule) do
          create(:code_owner_rule,
                 merge_request: merge_request,
                 users: code_owners,
                 name: '*.js')
        end

        before do
          code_owners.each { |user| project.add_developer(user) }
        end

        it 'shows the code owner rule as optional' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests
          expect(page).to have_content("Requires 1 approval from #{rule.name}.")

          find('[data-testid="widget-toggle"]').click
          wait_for_requests

          within('.mr-widget-workflow table .gl-font-monospace') do
            code_owner_row = find(:xpath, "//tr[td[contains(.,'#{code_owner_rule.name}')]]")

            expect(code_owner_row).to have_content('Optional')
          end
        end

        context 'when code owner approval is required' do
          before do
            stub_licensed_features(code_owner_approval_required: true, multiple_approval_rules: true)

            allow(ProtectedBranch)
              .to receive(:branch_requires_code_owner_approval?).and_return(true)
          end

          it 'shows the code owner rule as required' do
            visit project_merge_request_path(project, merge_request)
            wait_for_requests

            expect(page).to have_content("Requires 2 approvals from #{rule.name} and Code Owners")

            find('[data-testid="widget-toggle"]').click
            wait_for_requests

            within('.mr-widget-workflow table .gl-font-monospace') do
              code_owner_row = find(:xpath, "//tr[td[contains(.,'#{code_owner_rule.name}')]]")

              expect(code_owner_row).to have_content('0 of 1')
            end
          end
        end
      end
    end
  end
end
