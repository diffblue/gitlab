# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas', feature_category: :subscription_cost_management do
  include UsageQuotasHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let!(:project) do
    create(:project, :with_ci_minutes, amount_used: 100, namespace: group, shared_runners_enabled: true)
  end

  let(:gitlab_dot_com) { true }

  before do
    stub_feature_flags(usage_quotas_for_all_editions: false)
    allow(Gitlab).to receive(:com?).and_return(gitlab_dot_com)

    group.add_owner(user)
    sign_in(user)
  end

  describe 'Usage Quotas menu item' do
    it 'is linked within the group settings dropdown' do
      visit edit_group_path(group)

      page.within('.nav-sidebar') do
        expect(page).to have_link('Usage Quotas')
      end
    end

    context 'when checking namespace plan' do
      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'is linked within the group settings dropdown' do
        visit edit_group_path(group)

        page.within('.nav-sidebar') do
          expect(page).to have_link('Usage Quotas')
        end
      end
    end

    context 'when usage_quotas is not available' do
      before do
        stub_licensed_features(usage_quotas: false)
      end

      it 'is not linked within the group settings dropdown' do
        visit edit_group_path(group)

        page.within('.nav-sidebar') do
          expect(page).not_to have_link('Usage Quotas')
        end
      end

      it 'renders a 404' do
        visit_usage_quotas_page

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when accessing subgroup' do
    let(:root_ancestor) { create(:group) }
    let(:group) { create(:group, parent: root_ancestor) }

    it 'does not show subproject' do
      visit_usage_quotas_page

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'with pagination', :js do
    let(:per_page) { 1 }
    let(:item_selector) { '.js-project-link' }
    let(:prev_button_selector) { '[data-testid="prevButton"]' }
    let(:next_button_selector) { '[data-testid="nextButton"]' }
    let!(:projects) { create_list(:project, 3, :with_ci_minutes, amount_used: 5, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      stub_ee_application_setting(should_check_namespace_plan: true)
    end

    context 'on the storage tab' do
      before do
        visit_usage_quotas_page('storage-quota-tab')
      end

      it_behaves_like 'correct pagination'
    end
  end

  context 'with pending members', :js do
    let!(:awaiting_member) { create(:group_member, :awaiting, group: group) }

    it 'lists awaiting members and approves them' do
      visit pending_members_group_usage_quotas_path(group)

      expect(page.find('[data-testid="pending-members-row"]')).to have_text(awaiting_member.user.name)

      click_button 'Approve'
      click_button 'OK'
      wait_for_requests

      expect(awaiting_member.reload).to be_active
    end
  end

  context 'with storage limit', :js do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:active_members) { create_list(:group_member, 3, source: group) }

    before do
      stub_application_setting(check_namespace_plan: true)
    end

    context 'when over storage limit' do
      before do
        allow_next_found_instance_of(Group) do |instance|
          allow(instance).to receive(:over_storage_limit?).and_return true
        end
      end

      it 'shows active users' do
        visit_usage_quotas_page
        wait_for_requests

        active_user_names =  active_members.map { |m| m.user.name }

        expect(page.text).to include(*active_user_names)
      end
    end
  end

  context 'with free user limit', :js, :saas do
    let(:preview_free_user_cap) { false }
    let(:free_user_cap) { false }
    let(:awaiting_user_names) { awaiting_members.map { |m| m.user.name } }
    let(:active_user_names) { active_members.map { |m| m.user.name } }

    let_it_be(:group) { create(:group, :private) }
    let_it_be(:awaiting_members) { create_list(:group_member, 3, :awaiting, source: group) }
    let_it_be(:active_members) { create_list(:group_member, 3, source: group) }

    before do
      stub_feature_flags(preview_free_user_cap: preview_free_user_cap, free_user_cap: free_user_cap)
      stub_ee_application_setting(dashboard_limit_enabled: true)
      stub_ee_application_setting(dashboard_limit: 5)
      allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
        allow(instance).to receive(:execute).and_return([{ 'code' => 'ultimate', 'id' => 'ultimate-plan-id' }])
      end

      visit_usage_quotas_page
      wait_for_requests
    end

    context 'when no feature flag enabled' do
      it 'shows active users' do
        expect(page.text).not_to include(*awaiting_user_names)
        expect(page.text).to include(*active_user_names)
        expect(page).to have_content("You have 3 pending members")
        expect(page).to have_content("4 / Unlimited Seats in use")
      end
    end

    context 'when free_user_cap enabled' do
      let(:free_user_cap) { true }

      context 'when on a free plan' do
        it 'has correct seats in use and plans link' do
          expect(page).to have_content("4 / 5 Seats in use")
          expect(page).to have_link("Explore paid plans")
        end
      end

      context 'when on a paid plan' do
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, seats_in_use: 4, seats: 10, namespace: group) }

        it 'shows active users' do
          expect(page.text).not_to include(*awaiting_user_names)
          expect(page.text).to include(*active_user_names)
          expect(page).to have_content("You have 3 pending members")
          expect(page).to have_content("4 / 10 Seats in use")
        end
      end

      context 'when on a paid expired plan and over limit that is now free' do
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, :expired, :free, namespace: group) }

        let_it_be(:active_members) do
          create_list(:group_member, 2, source: group)
        end

        it 'shows usage quota alert' do
          expect(page).to have_content('Your free group is now limited to')
          expect(page).to have_link('upgrade')

          page.find("[data-testid='free-group-limited-dismiss']").click
          expect(page).not_to have_content('Your free group is now limited to')

          page.refresh
          expect(page).not_to have_content('Your free group is now limited to')
        end
      end

      context 'when on a trial' do
        let_it_be(:gitlab_subscription) do
          create(:gitlab_subscription, :active_trial, seats_in_use: 4, seats: 10, namespace: group)
        end

        it 'shows active users' do
          expect(page.text).not_to include(*awaiting_user_names)
          expect(page.text).to include(*active_user_names)
          expect(page).to have_content("You have 3 pending members")
          expect(page).to have_content("4 / Unlimited Seats in use")
        end
      end
    end
  end

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end
end
