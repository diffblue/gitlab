# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Members > Unlimited members alert', :js, :saas,
  feature_category: :subgroups do
  let(:alert_selector) { '[data-testid="unlimited-members-during-trial-alert"]' }
  let_it_be(:group) { create(:group, :private, name: 'unlimited-members-during-trial-alert-group') }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  context 'when group not in trial' do
    it 'does not display alert' do
      group.add_owner(user)
      project.add_owner(user)

      sign_in(user)

      visit project_project_members_path(project)

      wait_for_all_requests

      expect(page).not_to have_selector(alert_selector)
    end
  end

  context 'when group is in trial' do
    before do
      create(:gitlab_subscription, :active_trial, namespace: group)

      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when user is not owner' do
      it 'does not display alert' do
        group.add_maintainer(user)
        project.add_maintainer(user)
        sign_in(user)

        visit project_project_members_path(project)

        wait_for_all_requests

        expect(page).not_to have_selector(alert_selector)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
        project.add_owner(user)

        sign_in(user)
      end

      it_behaves_like 'unlimited members during trial alert' do
        let_it_be(:page_path) { project_project_members_path(project) }
      end
    end
  end
end
