# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Pipelines tab', :js, feature_category: :consumables_cost_management do
  include UsageQuotasHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let!(:project) do
    create(:project, :with_ci_minutes, amount_used: 100, namespace: group, shared_runners_enabled: true)
  end

  let(:gitlab_dot_com) { true }

  shared_context 'when user is allowed to see usage quotas' do
    before do
      stub_feature_flags(usage_quotas_for_all_editions: false)
      stub_ee_application_setting(should_check_namespace_plan: gitlab_dot_com)

      group.add_owner(user)
      sign_in(user)
      visit_usage_quotas_page
      wait_for_requests
    end
  end

  context 'with no quota' do
    include_context 'when user is allowed to see usage quotas'

    let(:group) { create(:group, :with_ci_minutes, ci_minutes_limit: nil) }

    it 'shows correct group quota info' do
      page.within('#pipelines-quota-tab') do
        expect(page).to have_content("400 / Unlimited minutes")
      end
    end
  end

  context 'with no projects using shared runners' do
    include_context 'when user is allowed to see usage quotas'

    let(:group) { create(:group, :with_not_used_build_minutes_limit) }
    let!(:project) { create(:project, namespace: group, shared_runners_enabled: false) }

    it 'shows correct group quota info' do
      page.within('#pipelines-quota-tab') do
        expect(page).to have_content("Unlimited")
      end

      page.within('[data-testid="pipelines-quota-tab-project-table"]') do
        expect(page).to have_content('Shared runners are disabled, so there are no limits set on pipeline usage')
      end
    end
  end

  context 'with minutes under quota' do
    include_context 'when user is allowed to see usage quotas'

    let(:group) { create(:group, :with_not_used_build_minutes_limit) }

    it 'shows correct group quota info' do
      page.within('#pipelines-quota-tab') do
        expect(page).to have_content("300 / 500 minutes")
        expect(page).to have_content("60% used")
      end
    end
  end

  context 'with minutes over quota' do
    include_context 'when user is allowed to see usage quotas'

    let(:group) { create(:group, :with_used_build_minutes_limit) }
    let!(:other_project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let!(:no_minutes_project) do
      create(:project, :with_ci_minutes, amount_used: 0, namespace: group, shared_runners_enabled: true)
    end

    context 'when it is not GitLab.com' do
      let(:gitlab_dot_com) { false }

      it "does not show 'Buy additional minutes' button" do
        expect(page).not_to have_content('Buy additional minutes')
      end
    end

    it 'has correct tracking setup and shows correct group quota and projects info' do
      page.within('#pipelines-quota-tab') do
        expect(page).to have_content("1000 / 500 minutes")
        expect(page).to have_content("200% used")
      end

      page.within('[data-testid="pipelines-quota-tab-project-table"]') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(other_project.full_name)
      end

      link = page.find('a', text: 'Buy additional minutes')

      expect(link['data-track-action']).to eq('click_buy_ci_minutes')
      expect(link['data-track-label']).to eq(group.actual_plan_name)
      expect(link['data-track-property']).to eq('pipeline_quota_page')
    end

    context 'in usage by project' do
      let(:per_page) { 20 }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
        visit_usage_quotas_page
      end

      it 'does not show projects with 0 minutes used' do
        page.within('[data-testid="pipelines-quota-tab-project-table"]') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(other_project.full_name)
          expect(page).not_to have_content(no_minutes_project.full_name)
        end
      end

      context 'when group has projects in subgroups' do
        let!(:subgroup) { create(:group, parent: group) }
        let!(:subproject) do
          create(:project, :with_ci_minutes, amount_used: 300, namespace: subgroup, shared_runners_enabled: true)
        end

        it 'shows projects inside the subgroup' do
          visit_usage_quotas_page

          expect(page).to have_content(project.full_name)
          expect(page).to have_content(subproject.full_name)
        end
      end
    end
  end

  describe 'Purchase additional CI minutes' do
    include_context 'when user is allowed to see usage quotas'

    it 'points to GitLab CI minutes purchase flow' do
      visit_usage_quotas_page

      expect(page).to have_link('Buy additional minutes', href: buy_minutes_subscriptions_link(group))
    end

    context 'when successfully purchasing CI Minutes' do
      let(:group) { create(:group, :with_ci_minutes) }
      let!(:project) do
        create(:project, :with_ci_minutes, amount_used: 200, namespace: group, shared_runners_enabled: true)
      end

      it 'does show a banner' do
        visit group_usage_quotas_path(group, purchased_product: 'CI minutes')

        page.within('#content-body') do
          expect(page).to have_content('Thanks for your purchase!')
          expect(page).to have_content(
            'You have successfully purchased CI minutes. You\'ll receive a receipt by email.'
          )
        end
      end
    end
  end

  context 'in projects usage table' do
    include_context 'when user is allowed to see usage quotas'

    let!(:project) do
      create(:project, :with_ci_minutes, amount_used: 100, shared_runners_duration: 1000, namespace: group,
                                         shared_runners_enabled: true)
    end

    let(:per_page) { 20 }
    let!(:subgroup) { create(:group, parent: group) }
    let!(:project2) do
      create(:project, :with_ci_minutes, amount_used: 5, shared_runners_duration: 50, namespace: group)
    end

    let!(:project3) do
      create(:project, :with_ci_minutes, amount_used: 3, shared_runners_duration: 30, namespace: subgroup)
    end

    let!(:project4) do
      create(:project, :with_ci_minutes, amount_used: 1, shared_runners_duration: 10, namespace: group)
    end

    let!(:project5) do
      create(:project, :with_ci_minutes, amount_used: 8, shared_runners_duration: 80, namespace: subgroup)
    end

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)

      visit_usage_quotas_page('pipelines-quota-tab')
    end

    it 'sorts projects list by CI minutes used in descending order' do
      page.within('[data-testid="pipelines-quota-tab-project-table"]') do
        expect(page).to have_content("Project")
        expect(page).to have_content("Shared runner duration")
        expect(page).to have_content("CI/CD minutes usage")

        shared_runner_durations = all('[data-testid="project_shared_runner_duration"]').map(&:text)
        expect(shared_runner_durations).to match_array(["16.67", "1.33", "0.83", "0.50", "0.17"])

        amounts_used = all('[data-testid="project_amount_used"]').map(&:text)
        expect(amounts_used).to match_array(%w[100 8 5 3 1])
      end
    end

    it 'displays info alert for table' do
      expect(page).to have_selector '[data-testid="project-usage-info-alert"]'
    end
  end

  context 'with pagination' do
    include_context 'when user is allowed to see usage quotas'

    let(:per_page) { 1 }
    let(:item_selector) { '[data-testid="pipelines-quota-tab-project-name"]' }
    let(:prev_button_selector) { '[data-testid="prevButton"]' }
    let(:next_button_selector) { '[data-testid="nextButton"]' }
    let!(:projects) { create_list(:project, 3, :with_ci_minutes, amount_used: 5, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      visit_usage_quotas_page
    end

    it_behaves_like 'correct pagination'
  end

  context 'when not the group owner' do
    before do
      stub_feature_flags(usage_quotas_for_all_editions: false)
      stub_ee_application_setting(should_check_namespace_plan: gitlab_dot_com)

      sign_in(user)
      visit_usage_quotas_page
      wait_for_requests
    end

    it 'shows no minutes quota info' do
      expect(page).not_to have_selector('#pipelines-quota-tab')
    end
  end

  def visit_usage_quotas_page(anchor = 'pipelines-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end
end
