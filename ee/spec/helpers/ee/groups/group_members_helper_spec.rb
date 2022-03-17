# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::GroupMembersHelper do
  include MembersPresentation

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe '.group_member_select_options' do
    before do
      helper.instance_variable_set(:@group, group)
    end

    it 'returns an options hash with skip_ldap' do
      expect(helper.group_member_select_options).to include(skip_ldap: false)
    end
  end

  describe '#group_members_app_data' do
    subject do
      helper.group_members_app_data(
        group,
        members: [],
        invited: [],
        access_requests: []
      )
    end

    before do
      allow(helper).to receive(:override_group_group_member_path).with(group, ':id').and_return('/groups/foo-bar/-/group_members/:id/override')
      allow(helper).to receive(:group_group_member_path).with(group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, group).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :export_group_memberships, group).and_return(true)
    end

    it 'adds `ldap_override_path`' do
      expect(subject[:user][:ldap_override_path]).to eq('/groups/foo-bar/-/group_members/:id/override')
    end

    it 'adds `can_export_members`' do
      expect(subject[:can_export_members]).to be true
    end

    it 'adds `export_csv_path`' do
      expect(subject[:export_csv_path]).not_to be_nil
    end

    it 'adds `can_filter_by_enterprise`' do
      allow(group.root_ancestor).to receive(:saml_enabled?).and_return(true)
      expect(subject[:can_filter_by_enterprise]).to eq(true)
    end
  end
end
