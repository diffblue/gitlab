# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas', :saas, feature_category: :consumables_cost_management do
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

  def visit_usage_quotas_page(anchor = 'seats-quota-tab')
    visit group_usage_quotas_path(group, anchor: anchor)
  end
end
