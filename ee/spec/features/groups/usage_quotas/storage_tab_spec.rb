# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Storage tab', :js, :saas, feature_category: :consumables_cost_management do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let!(:project) do
    create(:project, :with_ci_minutes, amount_used: 100, namespace: group, shared_runners_enabled: true)
  end

  before do
    stub_feature_flags(usage_quotas_for_all_editions: false)

    group.add_owner(user)
    sign_in(user)
  end

  context 'with pagination' do
    let(:per_page) { 1 }
    let(:item_selector) { '.js-project-link' }
    let(:prev_button_selector) { '[data-testid="prevButton"]' }
    let(:next_button_selector) { '[data-testid="nextButton"]' }
    let!(:projects) { create_list(:project, 3, :with_ci_minutes, amount_used: 5, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      stub_ee_application_setting(should_check_namespace_plan: true)
      visit_usage_quotas_page('storage-quota-tab')
    end

    it_behaves_like 'correct pagination'
  end

  context 'with storage limit' do
    let_it_be(:group) { create(:group, :private) }

    before do
      stub_application_setting(check_namespace_plan: true)
    end

    context 'when over storage limit' do
      before do
        allow_next_found_instance_of(Group) do |instance|
          allow(instance).to receive(:over_storage_limit?).and_return true
        end
      end

      it 'still displays the project under the group' do
        visit_usage_quotas_page('storage-quota-tab')
        wait_for_requests

        expect(page.text).to include(project.name)
      end
    end
  end

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end
end
