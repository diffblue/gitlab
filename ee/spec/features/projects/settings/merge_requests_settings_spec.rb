# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Project settings > [EE] Merge Requests', :js, feature_category: :code_review_workflow do
  include GitlabRoutingHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: user.namespace, path: 'gitlab', name: 'sample', group: group) }
  let_it_be(:group_member) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_owner(user)
    group.add_developer(group_member)
  end

  context 'Status checks' do
    context 'Feature is not available' do
      before do
        stub_licensed_features(external_status_checks: false)
      end

      it 'does not render the status checks area' do
        expect(page).not_to have_selector('[data-testid="status-checks-table"]')
      end
    end

    context 'Feature is available' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      it 'adds a status check' do
        visit project_settings_merge_requests_path(project)

        click_button 'Add status check'

        within('.modal-content') do
          find('[data-testid="name"]').set('My new check')
          find('[data-testid="url"]').set('https://api.gitlab.com')

          click_button 'Add status check'
        end

        wait_for_requests

        expect(find('[data-testid="status-checks-table"]')).to have_content('My new check')
      end

      context 'with a status check' do
        let_it_be(:rule) { create(:external_status_check, project: project) }

        it 'updates the status check' do
          visit project_settings_merge_requests_path(project)

          expect(find('[data-testid="status-checks-table"]')).to have_content(rule.name)

          within('[data-testid="status-checks-table"]') do
            click_button 'Edit'
          end

          within('.modal-content') do
            find('[data-testid="name"]').set('Something new')

            click_button 'Update status check'
          end

          wait_for_requests

          expect(find('[data-testid="status-checks-table"]')).to have_content('Something new')
        end

        it 'removes the status check' do
          visit project_settings_merge_requests_path(project)

          expect(find('[data-testid="status-checks-table"]')).to have_content(rule.name)

          within('[data-testid="status-checks-table"]') do
            click_button 'Remove...'
          end

          within('.modal-content') do
            click_button 'Remove status check'
          end

          wait_for_requests

          expect(find('[data-testid="status-checks-table"]')).not_to have_content(rule.name)
        end
      end
    end
  end

  context 'Issuable default templates' do
    context 'Feature is not available' do
      before do
        stub_licensed_features(issuable_default_templates: false)
      end

      it 'input to configure merge request template is not shown' do
        visit project_settings_merge_requests_path(project)

        expect(page).not_to have_selector('#project_merge_requests_template')
      end

      it "does not mention the merge request template in the section's description text" do
        visit project_settings_merge_requests_path(project)

        expect(page).to have_content('Choose your merge method, options, checks, and squash options.')
      end
    end

    context 'Feature is available' do
      before do
        stub_licensed_features(issuable_default_templates: true)
      end

      it 'input to configure merge request template is shown' do
        visit project_settings_merge_requests_path(project)

        expect(page).to have_selector('#project_merge_requests_template')
      end

      it "mentions the merge request template in the section's description text" do
        visit project_settings_merge_requests_path(project)

        expect(page).to have_content('Choose the method, options, checks, and squash options for merge requests. You can also set up merge request templates for different actions.')
      end
    end
  end

  context 'MR checks' do
    let(:merge_requests_settings_path) { project_settings_merge_requests_path(project) }

    it_behaves_like 'MR checks settings'
  end
end
