# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas' do
  include UsageQuotasHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let!(:project) { create(:project, :with_ci_minutes, amount_used: 100, namespace: group, shared_runners_enabled: true) }
  let(:gitlab_dot_com) { true }

  before do
    stub_feature_flags(usage_quotas_pipelines_vue: false)
    allow(Gitlab).to receive(:com?).and_return(gitlab_dot_com)

    group.add_owner(user)
    sign_in(user)
  end

  shared_examples 'linked in group settings dropdown' do
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

  context 'with no quota' do
    let(:group) { create(:group, :with_ci_minutes, ci_minutes_limit: nil) }

    include_examples 'linked in group settings dropdown'

    it 'shows correct group quota info' do
      visit_usage_quotas_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("400 / Unlimited minutes")
        expect(page).to have_selector('.bg-success')
      end
    end
  end

  context 'with no projects using shared runners' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }
    let!(:project) { create(:project, namespace: group, shared_runners_enabled: false) }

    include_examples 'linked in group settings dropdown'

    it 'shows correct group quota info' do
      visit_usage_quotas_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("0%")
        expect(page).to have_selector('.bg-success')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content('Shared runners are disabled, so there are no limits set on pipeline usage')
      end
    end
  end

  context 'minutes under quota' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }

    include_examples 'linked in group settings dropdown'

    it 'shows correct group quota info' do
      visit_usage_quotas_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / 500 minutes")
        expect(page).to have_content("60% used")
        expect(page).to have_selector('.bg-success')
      end
    end
  end

  context 'minutes over quota' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }
    let!(:other_project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let!(:no_minutes_project) { create(:project, :with_ci_minutes, amount_used: 0, namespace: group, shared_runners_enabled: true) }

    include_examples 'linked in group settings dropdown'

    context 'when it is not GitLab.com' do
      let(:gitlab_dot_com) { false }

      it "does not show 'Buy additional minutes' button" do
        visit_usage_quotas_page

        expect(page).not_to have_content('Buy additional minutes')
      end
    end

    it 'has correct tracking setup and shows correct group quota and projects info' do
      visit_usage_quotas_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("1000 / 500 minutes")
        expect(page).to have_content("200% used")
        expect(page).to have_selector('.bg-danger')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(other_project.full_name)
      end

      link = page.find('a', text: 'Buy additional minutes')

      expect(link['data-track-action']).to eq('click_buy_ci_minutes')
      expect(link['data-track-label']).to eq(group.actual_plan_name)
      expect(link['data-track-property']).to eq('pipeline_quota_page')
    end

    context 'usage by project' do
      let(:per_page) { 20 }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
        visit_usage_quotas_page
      end

      it 'does not show projects with 0 minutes used' do
        page.within('.pipeline-project-metrics') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(other_project.full_name)
          expect(page).not_to have_content(no_minutes_project.full_name)
        end
      end

      context 'when group has projects in subgroups' do
        let!(:subgroup) { create(:group, parent: group) }
        let!(:subproject) { create(:project, :with_ci_minutes, amount_used: 300, namespace: subgroup, shared_runners_enabled: true) }

        it 'shows projects inside the subgroup' do
          visit_usage_quotas_page

          expect(page).to have_content(project.full_name)
          expect(page).to have_content(subproject.full_name)
        end
      end
    end
  end

  describe 'Purchase additional CI minutes' do
    it 'points to GitLab CI minutes purchase flow' do
      visit_usage_quotas_page

      expect(page).to have_link('Buy additional minutes', href: buy_minutes_subscriptions_link(group))
    end

    context 'when successfully purchasing CI Minutes' do
      let(:group) { create(:group, :with_ci_minutes) }
      let!(:project) { create(:project, :with_ci_minutes, amount_used: 200, namespace: group, shared_runners_enabled: true) }

      it 'does show a banner' do
        visit group_usage_quotas_path(group, purchased_product: 'CI minutes')

        page.within('#content-body') do
          expect(page).to have_content('Thanks for your purchase!')
          expect(page).to have_content('You have successfully purchased CI minutes. You\'ll receive a receipt by email.')
        end
      end
    end
  end

  context 'Projects usage table' do
    let!(:project) { create(:project, :with_ci_minutes, amount_used: 100, shared_runners_duration: 1000, namespace: group, shared_runners_enabled: true) }

    let(:per_page) { 20 }
    let!(:subgroup) { create(:group, parent: group) }
    let!(:project2) { create(:project, :with_ci_minutes, amount_used: 5, shared_runners_duration: 50, namespace: group) }
    let!(:project3) { create(:project, :with_ci_minutes, amount_used: 3, shared_runners_duration: 30, namespace: subgroup) }
    let!(:project4) { create(:project, :with_ci_minutes, amount_used: 1, shared_runners_duration: 10, namespace: group) }
    let!(:project5) { create(:project, :with_ci_minutes, amount_used: 8, shared_runners_duration: 80, namespace: subgroup) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)

      visit_usage_quotas_page('pipelines-quota-tab')
    end

    it 'sorts projects list by CI minutes used in descending order' do
      page.within('.pipeline-project-metrics') do
        expect(page).to have_content("Project")
        expect(page).to have_content("Shared runner duration")
        expect(page).to have_content("CI/CD minutes usage")

        shared_runner_durations = all('[data-testid="project_shared_runner_duration"]').map(&:text)
        expect(shared_runner_durations).to eq(%w[17 1 1 1 0])

        amounts_used = all('[data-testid="project_amount_used"]').map(&:text)
        expect(amounts_used).to eq(%w[100 8 5 3 1])
      end
    end

    it 'displays info alert for table' do
      expect(page).to have_selector '[data-testid="project-usage-info-alert"]'
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

  context 'pagination', :js do
    let(:per_page) { 1 }
    let(:item_selector) { '.js-project-link' }
    let(:prev_button_selector) { '[data-testid="prevButton"]' }
    let(:next_button_selector) { '[data-testid="nextButton"]' }
    let!(:projects) { create_list(:project, 3, :with_ci_minutes, amount_used: 5, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      stub_ee_application_setting(should_check_namespace_plan: true)
    end

    context 'storage tab' do
      before do
        visit_usage_quotas_page('storage-quota-tab')
      end
      it_behaves_like 'correct pagination'
    end

    context 'pipelines tab: with usage_quotas_pipelines_vue disabled' do
      let(:item_selector) { '[data-testid="pipelines-quota-tab-project-name"]' }
      let(:prev_button_selector) { '.page-item.js-previous-button a' }
      let(:next_button_selector) { '.page-item.js-next-button a' }

      before do
        visit_usage_quotas_page('pipelines-quota-tab')
      end
      it_behaves_like 'correct pagination'
    end

    context 'pipelines tab: with usage_quotas_pipelines_vue enabled' do
      let(:item_selector) { '[data-testid="pipelines-quota-tab-project-name"]' }

      before do
        stub_feature_flags(usage_quotas_pipelines_vue: true)
        visit_usage_quotas_page('pipelines-quota-tab')
      end
      it_behaves_like 'correct pagination'
    end
  end

  context 'pending members', :js do
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

  context 'free user limit', :js, :saas do
    let(:preview_free_user_cap) { false }
    let(:free_user_cap) { false }
    let(:awaiting_user_names) { awaiting_members.map { |m| m.user.name } }
    let(:active_user_names) { active_members.map { |m| m.user.name } }

    let_it_be(:group) { create(:group) }
    let_it_be(:awaiting_members) { create_list(:group_member, 3, :awaiting, source: group) }
    let_it_be(:active_members) { create_list(:group_member, 3, source: group) }

    before do
      stub_feature_flags(preview_free_user_cap: preview_free_user_cap, free_user_cap: free_user_cap)
      group.namespace_settings.update_column(:include_for_free_user_cap_preview, preview_free_user_cap)

      stub_application_setting(check_namespace_plan: true)
      allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
        allow(instance).to receive(:execute).and_return([{ 'code' => 'ultimate', 'id' => 'ultimate-plan-id' }])
      end

      visit_usage_quotas_page
      wait_for_requests
    end

    context 'when no feature flag enabled' do
      it 'shows active users and does not show seat toggles' do
        expect(page).not_to have_selector("[data-testid='seat-toggle']")
        expect(page.text).not_to include(*awaiting_user_names)
        expect(page.text).to include(*active_user_names)
        expect(page).to have_content("You have 3 pending members")
        expect(page).to have_content("4 / Unlimited Seats in use")
      end
    end

    context 'when preview_free_user_cap enabled' do
      let(:preview_free_user_cap) { true }

      it 'can change seat state but does not enforce limits' do
        expect(page).to have_content("4 / Unlimited Seats in use")
        expect(find_toggles.count).to eq(7)
        expect(find_toggles(:disabled).count).to eq(1)
        expect(find_toggles(:checked).count).to eq(4)
        expect(find_toggles(:unchecked).count).to eq(3)

        find_toggles(:unchecked).first.click
        wait_for_requests

        find_toggles(:unchecked).first.click
        wait_for_requests

        expect(page).to have_content("6 / Unlimited Seats in use")
        expect(find_toggles.count).to eq(7)
        expect(find_toggles(:disabled).count).to eq(1)
        expect(find_toggles(:checked).count).to eq(6)
        expect(find_toggles(:unchecked).count).to eq(1)
      end
    end

    context 'when free_user_cap enabled' do
      let(:free_user_cap) { true }

      context 'when on a free plan' do
        it 'can change seat state and enforces limit' do
          expect(page).to have_content("4 / 5 Seats in use")
          expect(page).to have_link("Explore all plans")
          expect(find_toggles.count).to eq(7)
          expect(find_toggles(:disabled).count).to eq(1)
          expect(find_toggles(:checked).count).to eq(4)
          expect(find_toggles(:unchecked).count).to eq(3)

          find_toggles(:unchecked).first.click
          wait_for_requests

          expect(page).to have_content("5 / 5 Seats in use")
          expect(find_toggles.count).to eq(7)
          expect(find_toggles(:disabled).count).to eq(3)
          expect(find_toggles(:checked).count).to eq(5)
          expect(find_toggles(:unchecked).count).to eq(2)
        end
      end

      context 'when on a paid plan' do
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, seats_in_use: 4, seats: 10, namespace: group) }

        it 'shows active users and does not show seat toggles' do
          expect(page).not_to have_selector("[data-testid='seat-toggle']")
          expect(page.text).not_to include(*awaiting_user_names)
          expect(page.text).to include(*active_user_names)
          expect(page).to have_content("You have 3 pending members")
          expect(page).to have_content("4 / 10 Seats in use")
        end
      end

      context 'when on a paid expired plan and over limit that is now free' do
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, :expired, :free, namespace: group) }

        let_it_be(:active_members) do
          create_list(:group_member, ::Namespaces::FreeUserCap::FREE_USER_LIMIT + 1, source: group)
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
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, :active_trial, seats_in_use: 4, seats: 10, namespace: group) }

        it 'shows active users and does not show seat toggles' do
          expect(page).not_to have_selector("[data-testid='seat-toggle']")
          expect(page.text).not_to include(*awaiting_user_names)
          expect(page.text).to include(*active_user_names)
          expect(page).to have_content("You have 3 pending members")
          expect(page).to have_content("4 / 10 Seats in use")
        end
      end
    end
  end

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end

  def click_next_page_pipeline_projects
    page.find('.gl-pagination .pagination .js-next-button').click
    wait_for_requests
  end

  def find_toggles(state = nil)
    query = case state
            when :checked
              '.is-checked'
            when :disabled
              '.is-disabled'
            when :unchecked
              ':not(.is-checked)'
            else
              ''
            end

    page.find_all("[data-testid='seat-toggle'] button#{query}")
  end
end
