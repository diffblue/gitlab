# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/group_members/index' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(view).to receive(:group_members_app_data).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('shared/_free_user_cap_alert')
    end
  end

  context 'when managing members text is present' do
    before do
      allow(view).to receive(:can_admin_group_member?).with(group).and_return(true)
      allow(view).to receive(:can?).with(user, :admin_group_member, group.root_ancestor).and_return(true)
      allow(::Namespaces::FreeUserCap).to receive(:enforce_preview_or_standard?)
                                            .with(group.root_ancestor).and_return(true)
    end

    it 'renders as expected' do
      render

      expect(rendered).to have_content('Group members')
      expect(rendered).to have_content("You're viewing members of")
      expect(rendered).to have_content('To manage seats for all members associated with this group and its subgroups')
      expect(rendered).to have_link('usage quotas page', href: group_usage_quotas_path(group.root_ancestor))
    end
  end
end
