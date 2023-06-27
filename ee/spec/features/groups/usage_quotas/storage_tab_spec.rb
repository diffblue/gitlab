# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Storage tab', :js, :saas, feature_category: :consumables_cost_management do
  include NamespaceStorageHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :premium_plan) }
  let_it_be(:root_storage_statistics, refind: true) { create(:namespace_root_storage_statistics, namespace: group) }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_feature_flags(usage_quotas_for_all_editions: false)
    stub_application_setting(check_namespace_plan: true)

    sign_in(user)
  end

  context 'with pagination' do
    let(:per_page) { 1 }
    let(:item_selector) { '.js-project-link' }
    let(:prev_button_selector) { '[data-testid="prevButton"]' }
    let(:next_button_selector) { '[data-testid="nextButton"]' }
    let!(:projects) { create_list(:project, 3, namespace: group) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
      visit_usage_quotas_page('storage-quota-tab')
    end

    it_behaves_like 'correct pagination'
  end

  context 'with namespace storage limit' do
    let_it_be(:project) { create(:project, namespace: group) }

    before do
      enforce_namespace_storage_limit(group)
      set_enforcement_limit(group, megabytes: 100)
    end

    context 'when over storage limit' do
      before do
        set_used_storage(group, megabytes: 105)
      end

      it 'still displays the project under the group' do
        visit_usage_quotas_page('storage-quota-tab')

        expect(page).to have_text(project.name)
      end
    end
  end

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end
end
