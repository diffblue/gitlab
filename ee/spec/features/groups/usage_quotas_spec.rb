# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas' do
  include UsageQuotasHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let!(:project) { create(:project, :with_ci_minutes, amount_used: 100, namespace: group, shared_runners_enabled: true) }
  let(:gitlab_dot_com) { true }

  before do
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

  context 'projects usage table' do
    let!(:project) { create(:project, :with_ci_minutes, amount_used: 100, shared_runners_duration: 50, namespace: group, shared_runners_enabled: true) }

    it 'displays correct table data' do
      visit_usage_quotas_page

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content("Project")
        expect(page).to have_content("Shared runner usage")
        expect(page).to have_content("CI/CD minutes usage")
        expect(find('[data-testid="project_shared_runner_duration"]')).to have_text('50')
        expect(find('[data-testid="project_amount_used"]')).to have_text('100')
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

    context 'feature flag :ci_show_all_projects_with_usage_sorted_descending is enabled' do
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
    end

    context 'feature flag :ci_show_all_projects_with_usage_sorted_descending is disabled' do
      let(:per_page) { 20 }

      before do
        stub_feature_flags(ci_show_all_projects_with_usage_sorted_descending: false)
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
        visit_usage_quotas_page
      end

      it 'shows projects with 0 minutes used' do
        page.within('.pipeline-project-metrics') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(other_project.full_name)
          expect(page).to have_content(no_minutes_project.full_name)
        end
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

  context 'if feature flag :ci_show_all_projects_with_usage_sorted_descending is enabled when accessing root group' do
    let!(:subgroup) { create(:group, parent: group) }
    let!(:subproject) { create(:project, :with_ci_minutes, amount_used: 300, namespace: subgroup, shared_runners_enabled: true) }

    it 'does show projects of subgroup' do
      visit_usage_quotas_page

      expect(page).to have_content(project.full_name)
      expect(page).to have_content(subproject.full_name)
    end
  end

  context 'when purchasing CI minutes' do
    it 'points to GitLab CI minutes purchase flow' do
      visit_usage_quotas_page

      expect(page).to have_link('Buy additional minutes', href: buy_minutes_subscriptions_link(group))
    end
  end

  context 'pagination', :js do
    let(:per_page) { 1 }
    let!(:projects) { create_list(:project, 3, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)

      visit_usage_quotas_page('storage-quota-tab')
    end

    it 'paginates correctly to page 3 and back' do
      expect(page).to have_selector('.js-project-link', count: per_page)
      page1_el_text = page.find('.js-project-link').text
      click_next_page

      expect(page).to have_selector('.js-project-link', count: per_page)
      page2_el_text = page.find('.js-project-link').text
      click_next_page

      expect(page).to have_selector('.js-project-link', count: per_page)
      page3_el_text = page.find('.js-project-link').text
      click_prev_page

      expect(page3_el_text).not_to eql(page2_el_text)
      expect(page.find('.js-project-link').text).to eql(page2_el_text)

      click_prev_page

      expect(page.find('.js-project-link').text).to eql(page1_el_text)
      expect(page).to have_selector('.js-project-link', count: per_page)
    end
  end

  context 'sorting when feature flag :ci_show_all_projects_with_usage_sorted_descending is enabled', :js do
    let(:per_page) { 3 }
    let!(:subgroup) { create(:group, parent: group) }
    let!(:project2) { create(:project, :with_ci_minutes, amount_used: 5, namespace: group) }
    let!(:project3) { create(:project, :with_ci_minutes, amount_used: 3, namespace: subgroup) }
    let!(:project4) { create(:project, :with_ci_minutes, amount_used: 1, namespace: group) }
    let!(:project5) { create(:project, :with_ci_minutes, amount_used: 8, namespace: subgroup) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)

      visit_usage_quotas_page('pipelines-quota-tab')
    end

    it 'sorts projects list by CI minutes used in descending order' do
      expect(page).to have_selector('.pipeline-project-metrics')

      expect(page.text.index(project5.full_name)).to be < page.text.index(project2.full_name)
      click_next_page_pipeline_projects
      expect(page.text.index(project3.full_name)).to be < page.text.index(project4.full_name)
    end
  end

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end

  def click_next_page_pipeline_projects
    page.find('.gl-pagination .pagination .js-next-button').click
    wait_for_requests
  end

  def click_next_page
    page.find('[data-testid="nextButton"]').click
    wait_for_requests
  end

  def click_prev_page
    page.find('[data-testid="prevButton"]').click
    wait_for_requests
  end
end
