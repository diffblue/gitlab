# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Display license check deprecation alert', :js, feature_category: :projects do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }
  let_it_be(:project_approvers) { create_list(:user, 3) }

  before_all do
    project.add_guest(user)
    create(:approval_project_rule,
      :license_scanning,
      name: "License-Check",
      project: project,
      users: project_approvers,
      approvals_required: 1)
  end

  before do
    sign_in(user)
  end

  context 'when license_scanning_policies is enabled' do
    before do
      stub_feature_flags(license_scanning_policies: true)
    end

    context 'with a license check approval rule' do
      it 'does show the alert' do
        visit project_path(project)

        expect(page).to have_css('.js-license-check-deprecation-alert')
      end
    end

    context 'without a license check approval rule' do
      let_it_be(:non_license_check_project) { create(:project, :repository) }

      before do
        non_license_check_project.add_guest(user)
        sign_in(user)
      end

      it 'does not show the alert' do
        visit project_path(non_license_check_project)

        expect(page).to have_css('.js-show-on-project-root')

        expect(page).not_to have_css('.js-license-check-deprecation-alert')
      end
    end

    context 'when user dimisses the alert' do
      context 'in the same project' do
        it 'does not show the alert' do
          visit project_path(project)

          expect(page).to have_css('.js-license-check-deprecation-alert')

          close_callout

          page.refresh

          expect(page).to have_css('.js-show-on-project-root')

          expect(page).not_to have_css('.js-license-check-deprecation-alert')
        end
      end

      context 'in a different project' do
        let_it_be(:other_project) { create(:project, :repository) }

        before do
          other_project.add_guest(user)
          create(:approval_project_rule,
            :license_scanning,
            name: "License-Check",
            project: other_project,
            users: project_approvers,
            approvals_required: 1)
        end

        it 'does not show the callout' do
          visit project_path(project)

          expect(page).to have_css('.js-license-check-deprecation-alert')

          close_callout

          visit project_path(other_project)

          expect(page).to have_css('.js-license-check-deprecation-alert')
        end
      end
    end
  end

  context 'when license_scanning_policies is disabled' do
    before do
      stub_feature_flags(license_scanning_policies: false)
    end

    it 'requires approval' do
      visit project_path(project)

      expect(page).to have_css('.js-show-on-project-root')

      expect(page).not_to have_css('.js-license-check-deprecation-alert')
    end
  end

  def close_callout
    find('[data-testid="dismiss-license-check-deprecation-alert"]').click

    expect(page).to have_css('.js-show-on-project-root')

    expect(page).not_to have_css('.js-license-check-deprecation-alert')
  end
end
