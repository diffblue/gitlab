# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees status checks widget', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:check1) { create(:external_status_check, project: project) }
  let_it_be(:check2) { create(:external_status_check, project: project) }

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:status_check_response) { create(:status_check_response, external_status_check: check1, merge_request: merge_request, sha: merge_request.source_branch_sha) }

  shared_examples 'no status checks widget' do
    it 'does not show the widget' do
      expect(page).not_to have_selector('[data-test-id="mr-status-checks"]')
    end
  end

  before do
    stub_licensed_features(external_status_checks: true)
  end

  context 'user is authorized' do
    before do
      stub_feature_flags(refactor_mr_widgets_extensions: false)
      stub_feature_flags(refactor_mr_widgets_extensions_user: false)

      project.add_maintainer(user)
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows the widget' do
      expect(page).to have_content('Status checks 1 pending')
    end

    it 'shows the status check issues', :aggregate_failures do
      within '[data-test-id="mr-status-checks"]' do
        click_button 'Expand'
      end

      [check1, check2].each do |rule|
        within "[data-testid='mr-status-check-issue-#{rule.id}']" do
          icon_type = rule.approved?(merge_request, merge_request.source_branch_sha) ? 'success' : 'pending'
          expect(page).to have_css(".ci-status-icon-#{icon_type}")
          expect(page).to have_content("#{rule.name}, #{rule.external_url}")
        end
      end
    end
  end

  context 'widget extension flag is enabled' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows the widget' do
      expect(page).to have_content('Status checks 1 pending')
    end

    it 'shows the status check issues', :aggregate_failures do
      within '[data-testid="widget-extension"]' do
        find('[data-testid="toggle-button"]').click
      end

      [check1, check2].each do |rule|
        icon_type = rule.approved?(merge_request, merge_request.source_branch_sha) ? 'success' : 'neutral'
        expect(page).to have_css("[data-testid='status-#{icon_type}-icon']")
        expect(page).to have_content("#{rule.name}: #{rule.external_url}")
      end
    end
  end

  context 'user is not logged in' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    it_behaves_like 'no status checks widget'
  end
end
