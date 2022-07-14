# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::GroupMembersHelper do
  include MembersPresentation
  using RSpec::Parameterized::TableSyntax

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
    let(:banned) { present_members(create_list(:group_member, 2, group: group, created_by: current_user)) }

    subject do
      helper.group_members_app_data(
        group,
        members: [],
        invited: [],
        access_requests: [],
        banned: banned,
        include_relations: [:inherited, :direct],
        search: nil
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

    context 'banned members' do
      it 'returns `members` property that matches json schema' do
        expect(subject[:banned][:members].to_json).to match_schema('members')
      end

      it 'sets `member_path` property' do
        expect(subject[:banned][:member_path]).to eq('/groups/foo-bar/-/group_members/:id')
      end

      context 'when banned arg is nil' do
        let(:banned) { nil }

        it 'returns `members` property is an empty array' do
          expect(subject[:banned][:members]).to eq []
        end
      end
    end
  end

  describe '#group_member_header_subtext' do
    let(:base_subtext) { "You can invite a new member to <strong>#{group.name}</strong>." }
    let(:standard_subtext) { "^#{base_subtext}$" }
    let(:enforcement_subtext) { "^#{base_subtext}<br />To manage all members" }

    where(:can_admin_member, :enforce_free_user_cap, :subtext) do
      true  | true  | ref(:enforcement_subtext)
      true  | false | ref(:standard_subtext)
      false | true  | ref(:standard_subtext)
      false | false | ref(:standard_subtext)
    end

    before do
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, group).and_return(can_admin_member)
      allow(::Namespaces::FreeUserCap).to receive(:enforce_preview_or_standard?)
                                                      .with(group).and_return(enforce_free_user_cap)
    end

    with_them do
      it 'contains expected text' do
        expect(helper.group_member_header_subtext(group)).to match(subtext)
      end
    end
  end
end
