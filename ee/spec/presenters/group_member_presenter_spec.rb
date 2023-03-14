# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMemberPresenter do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build_stubbed(:user) }
  let(:group) { double(:group) }
  let(:group_member) { double(:group_member, source: group, user: user) }
  let(:presenter) { described_class.new(group_member, current_user: user) }

  describe '#group_sso?' do
    let(:saml_provider) { build_stubbed(:saml_provider) }
    let(:group) { saml_provider.group }

    context 'when member does not have a user (invited member)' do
      let(:group_member) { build_stubbed(:group_member, :invited) }

      it 'returns `false`' do
        expect(presenter.group_sso?).to eq false
      end
    end

    context 'when group is a root group' do
      it 'calls through to User#group_sso?' do
        expect(user).to receive(:group_sso?).with(group).and_return(true)

        expect(presenter.group_sso?).to eq true
      end
    end

    context 'when group is a child group' do
      let(:parent_group) { build_stubbed(:group) }

      before do
        allow(group).to receive(:root_ancestor).and_return(parent_group)
      end

      it 'calls through to User#group_sso? with root group' do
        expect(user).to receive(:group_sso?).with(parent_group).and_return(true)

        expect(presenter.group_sso?).to eq true
      end
    end
  end

  describe '#group_managed_account?' do
    context 'when member does not have a user (invited member)' do
      let(:group_member) { build(:group_member, :invited) }

      it 'returns `false`' do
        expect(presenter.group_managed_account?).to eq false
      end
    end

    context 'when user is part of the group managed account' do
      before do
        expect(user).to receive(:group_managed_account?).and_return(true)
      end

      it 'returns `true`' do
        expect(presenter.group_managed_account?).to eq true
      end
    end

    context 'when user is not part of the group managed account' do
      before do
        expect(user).to receive(:group_managed_account?).and_return(false)
      end

      it 'returns `false`' do
        expect(presenter.group_managed_account?).to eq false
      end
    end
  end

  describe '#can_update?' do
    context 'when user cannot update_group_member but can override_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(true)
      end

      it { expect(presenter.can_update?).to eq(true) }
    end

    context 'when user cannot update_group_member and cannot override_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(false)
      end

      it { expect(presenter.can_update?).to eq(false) }
    end
  end

  describe '#valid_level_roles?' do
    context 'with minimal access role feature switched on' do
      before do
        allow(group_member).to receive(:highest_group_member)
        allow(group_member).to receive_message_chain(:class, :access_level_roles).and_return(::Gitlab::Access.options_with_owner)
        expect(group).to receive(:access_level_roles).and_return(::Gitlab::Access.options_with_minimal_access)
      end

      it { expect(presenter.valid_level_roles).to eq(::Gitlab::Access.options_with_minimal_access) }
    end

    context 'with minimal access role feature switched off' do
      it_behaves_like '#valid_level_roles', :group do
        let(:expected_roles) { { 'Developer' => 30, 'Maintainer' => 40, 'Owner' => 50, 'Reporter' => 20 } }

        before do
          entity.update!(parent: group)
        end
      end
    end
  end

  describe '#can_ban?' do
    let(:current_user) { instance_double(User) }
    let(:presenter) { described_class.new(group_member, current_user: current_user) }

    where(:can_ban_group_member, :member_is_owner, :result) do
      false | false | false
      false | true  | false
      true  | false | true
      true  | true  | false
    end

    with_them do
      before do
        allow(presenter).to receive(:can?).with(current_user, :ban_group_member, group).and_return(can_ban_group_member)
        allow(group_member).to receive(:owner?).and_return(member_is_owner)
      end

      it { expect(presenter.can_ban?).to eq(result) }
    end
  end

  describe '#can_unban?' do
    before do
      allow(presenter).to receive(:can?).with(user, :admin_group_member, presenter) { can_admin_group_member }
    end

    context 'when user can admin_group_member' do
      let(:can_admin_group_member) { true }

      it { expect(presenter.can_unban?).to eq(true) }
    end

    context 'when user cannot admin_group_member' do
      let(:can_admin_group_member) { false }

      it { expect(presenter.can_unban?).to eq(false) }
    end
  end
end
