# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/namespace_user_cap_reached_alert' do
  let_it_be(:group, refind: true) { create(:group, namespace_settings: create(:namespace_settings, new_user_signups_cap: 1)) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:other_group) { create(:group, namespace_settings: create(:namespace_settings, new_user_signups_cap: 1)) }
  let_it_be(:project, refind: true) { create(:project, namespace: other_group) }
  let_it_be(:owner) { create(:user) }

  let(:partial) { 'shared/namespace_user_cap_reached_alert' }

  before_all do
    group.add_owner(owner)
    other_group.add_owner(owner)
  end

  before do
    allow(view).to receive(:current_user).and_return(owner)
  end

  it 'renders a link to pending user approvals' do
    assign(:group, group)

    render partial

    expect(rendered).to have_link('View pending user approvals', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))
  end

  it 'renders a link to the root namespace pending user approvals' do
    assign(:group, subgroup)

    render partial

    expect(rendered).to have_link('View pending user approvals', href: usage_quotas_path(group, anchor: 'seats-quota-tab'))
  end

  it 'renders a link to the project namespace pending user approvals' do
    assign(:group, group)
    assign(:project, project)

    render partial

    expect(rendered).to have_link('View pending user approvals', href: usage_quotas_path(project.namespace, anchor: 'seats-quota-tab'))
  end
end
