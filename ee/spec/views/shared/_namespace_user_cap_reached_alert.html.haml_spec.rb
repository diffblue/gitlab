# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/namespace_user_cap_reached_alert' do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project) }

  let(:partial) { 'shared/namespace_user_cap_reached_alert' }

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
