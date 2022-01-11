# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/namespace_user_cap_reached_alert', :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

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
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_cache(group)
    stub_cache(other_group)
  end

  it 'renders a link to pending user approvals' do
    assign(:group, group)

    render partial

    expect(rendered).to have_link('View pending approvals', href: pending_members_group_usage_quotas_path(group))
  end

  it 'renders a link to the root namespace pending user approvals' do
    assign(:group, subgroup)

    render partial

    expect(rendered).to have_link('View pending approvals', href: pending_members_group_usage_quotas_path(group))
  end

  it 'renders a link to the project namespace pending user approvals' do
    assign(:group, group)
    assign(:project, project)

    render partial

    expect(rendered).to have_link('View pending approvals', href: pending_members_group_usage_quotas_path(project.namespace))
  end

  def stub_cache(group)
    group_with_fresh_memoization = Group.find(group.id)
    result = group_with_fresh_memoization.calculate_reactive_cache
    stub_reactive_cache(group, result)
  end
end
