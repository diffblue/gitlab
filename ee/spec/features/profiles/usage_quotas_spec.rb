# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Usage Quota', :js, feature_category: :consumables_cost_management do
  include ::Ci::MinutesHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:namespace, reload: true) { user.namespace }
  let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: namespace) }
  let_it_be(:project, reload: true) { create(:project, namespace: namespace) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    sign_in(user)
  end

  it 'is linked within the profile page' do
    visit profile_path

    page.within('.nav-sidebar') do
      expect(page).to have_selector(:link_or_button, 'Usage Quotas')
    end
  end

  describe 'shared runners use' do
    where(:shared_runners_enabled, :used, :quota, :usage_text) do
      false | 300  | 500 | '300 / Not supported minutes Unlimited'
      true  | 300  | nil | '300 / Unlimited minutes Unlimited'
      true  | 300  | 500 | '300 / 500 minutes 60% used'
      true  | 1000 | 500 | '1000 / 500 minutes 200% used'
    end

    with_them do
      let(:no_shared_runners_text) { 'Shared runners are disabled, so there are no limits set on pipeline usage' }

      before do
        project.update!(shared_runners_enabled: shared_runners_enabled)
        set_ci_minutes_used(namespace, used, project: project)
        namespace.update!(shared_runners_minutes_limit: quota)

        visit_usage_quotas_page
        wait_for_requests
      end

      it 'shows the correct quota status' do
        page.within('#pipelines-quota-tab') do
          expect(page).to have_content(usage_text)
        end
      end

      it 'shows the correct per-project metrics' do
        page.within('[data-testid="pipelines-quota-tab-project-table"]') do
          expect(page).to have_content(project.name)

          if shared_runners_enabled
            expect(page).not_to have_content(no_shared_runners_text)
          else
            expect(page).to have_content(no_shared_runners_text)
          end
        end
      end
    end

    context 'with pagination' do
      let(:per_page) { 1 }
      let(:item_selector) { '.js-project-link' }
      let(:prev_button_selector) { '[data-testid="prevButton"]' }
      let(:next_button_selector) { '[data-testid="nextButton"]' }
      let!(:projects) { create_list(:project, 3, :with_ci_minutes, amount_used: 5, namespace: namespace) }

      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      end

      context 'on storage tab' do
        before do
          visit_usage_quotas_page('storage-quota-tab')
        end

        it_behaves_like 'correct pagination'
      end

      context 'on pipelines tab', feature_category: :continuous_integration do
        let(:item_selector) { '[data-testid="pipelines-quota-tab-project-name"]' }

        before do
          visit_usage_quotas_page
        end

        it_behaves_like 'correct pagination'
      end
    end
  end

  def visit_usage_quotas_page(anchor = 'pipelines-quota-tab')
    visit profile_usage_quotas_path(namespace, anchor: anchor)
  end
end
