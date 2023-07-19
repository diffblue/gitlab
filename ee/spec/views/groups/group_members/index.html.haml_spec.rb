# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/group_members/index', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:group) { create(:group) } # rubocop:todo RSpec/FactoryBot/AvoidCreate

  before do
    allow(view).to receive(:group_members_app_data).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
  end

  context 'when managing members text is present' do
    before do
      allow(view).to receive(:can_admin_group_member?).with(group).and_return(true)
      allow(view).to receive(:can?).with(user, :admin_group_member, group.root_ancestor).and_return(true)
      allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement, group.root_ancestor) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(true)
      end
    end

    it 'renders as expected' do
      render

      expect(rendered).to have_content('Group members')
      expect(rendered).to have_content("You're viewing members of")
      expect(rendered).not_to have_link(_('Create service account'), href: new_group_service_account_path(group))
      expect(rendered).to have_content('To manage seats for all members associated with this group and its subgroups')
      expect(rendered).to have_link('usage quotas page', href: group_usage_quotas_path(group.root_ancestor))
    end

    context 'when managing service account is enabled' do
      before do
        allow(view).to receive(:can_admin_service_accounts?).with(group).and_return(true)
      end

      it 'display button to create service accounts' do
        render

        expect(rendered).to have_link(_('Create service account'), href: new_group_service_account_path(group))
      end
    end
  end
end
