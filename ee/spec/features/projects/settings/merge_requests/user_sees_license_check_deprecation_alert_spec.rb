# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Display license check deprecation alert', :js, feature_category: :projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:project_approvers) { create_list(:user, 3) }

  before_all do
    create(:approval_project_rule,
      :license_scanning,
      name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT,
      project: project,
      users: project_approvers,
      approvals_required: 1)
  end

  before do
    sign_in(user)
  end

  context 'in the merge request settings page' do
    it 'shows the alert message' do
      visit project_settings_merge_requests_path(project)

      expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')
    end
  end

  context 'when user dismisses callout by clicking on the close button' do
    it 'hides callout' do
      visit project_settings_merge_requests_path(project)

      expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')

      close_callout

      page.refresh

      expect(page).to have_css('#js-merge-request-approval-settings')

      expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
    end

    context 'in a different project' do
      let_it_be(:other_project) { create(:project) }

      before do
        other_project.add_owner(user)
        create(:approval_project_rule,
          :license_scanning,
          name: "License-Check",
          project: other_project,
          users: project_approvers,
          approvals_required: 1)
      end

      it 'still shows the callout' do
        visit project_settings_merge_requests_path(project)

        expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')

        close_callout

        visit project_settings_merge_requests_path(other_project)

        expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')
      end
    end

    context 'in a different project without license check approval rule' do
      let_it_be(:non_license_check_project) { create(:project) }

      before do
        non_license_check_project.add_owner(user)
      end

      it 'does not show the callout' do
        visit project_settings_merge_requests_path(non_license_check_project)

        expect(page).to have_css('#js-merge-request-approval-settings')

        expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
      end
    end
  end

  context 'when user dismisses callout by clicking on the dismiss button' do
    it 'hides callout' do
      visit project_settings_merge_requests_path(project)

      expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')

      dismiss_callout

      page.refresh

      expect(page).to have_css('#js-merge-request-approval-settings')

      expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
    end

    context 'in a different project' do
      let_it_be(:other_project) { create(:project) }

      before do
        other_project.add_owner(user)
        create(:approval_project_rule,
          :license_scanning,
          name: "License-Check",
          project: other_project,
          users: project_approvers,
          approvals_required: 1)
      end

      it 'still shows the callout' do
        visit project_settings_merge_requests_path(project)

        expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')

        dismiss_callout

        visit project_settings_merge_requests_path(other_project)

        expect(page).to have_css('[data-testid="settings-license-check-deprecation-alert"]')
      end
    end

    context 'in a different project without license check approval rule' do
      let_it_be(:non_license_check_project) { create(:project) }

      before do
        non_license_check_project.add_owner(user)
      end

      it 'does not show the callout' do
        visit project_settings_merge_requests_path(non_license_check_project)

        expect(page).to have_css('#js-merge-request-approval-settings')

        expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
      end
    end
  end

  def close_callout
    find('[data-testid="dismiss-settings-license-check-deprecation-alert"]').click

    expect(page).to have_css('#js-merge-request-approval-settings')

    expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
  end

  def dismiss_callout
    find('[data-testid="settings-license-check-deprecation-alert-dismiss-button"]').click

    expect(page).to have_css('#js-merge-request-approval-settings')

    expect(page).not_to have_css('[data-testid="settings-license-check-deprecation-alert"]')
  end
end
