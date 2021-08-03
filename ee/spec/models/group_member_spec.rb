# frozen_string_literal: true
require 'spec_helper'

RSpec.describe GroupMember do
  it { is_expected.to include_module(EE::GroupMember) }

  it_behaves_like 'member validations'

  describe 'validations' do
    describe '#group_domain_validations' do
      let(:member_type) { :group_member }
      let(:source) { group }
      let(:nested_source) { create(:group, parent: group) }

      it_behaves_like 'member group domain validations'
    end

    describe 'access level inclusion' do
      let(:group) { create(:group) }

      context 'when minimal access user feature switched on' do
        before do
          stub_licensed_features(minimal_access_role: true)
        end

        it 'users can have access levels from minimal access to owner' do
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::NO_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::GUEST)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::REPORTER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::DEVELOPER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MAINTAINER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::OWNER)).to be_valid
        end

        context 'when group is a subgroup' do
          let(:subgroup) { create(:group, parent: group) }

          it 'users cannot have minimal access level' do
            expect(build(:group_member, group: subgroup, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_invalid
          end
        end
      end

      context 'when minimal access user feature switched off' do
        before do
          stub_licensed_features(minimal_access_role: false)
        end

        it 'users can have access levels from guest to owner' do
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::NO_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MINIMAL_ACCESS)).to be_invalid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::GUEST)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::REPORTER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::DEVELOPER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::MAINTAINER)).to be_valid
          expect(build(:group_member, group: group, user: create(:user), access_level: ::Gitlab::Access::OWNER)).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:group) { create(:group) }
    let_it_be(:member1) { create(:group_member, group: group) }
    let_it_be(:member2) { create(:group_member, group: group) }
    let_it_be(:member3) { create(:group_member) }
    let_it_be(:guest1) { create(:group_member, :guest) }
    let_it_be(:guest2) { create(:group_member, :guest, group: group) }

    describe '.by_group_ids' do
      it 'returns only members from selected groups' do
        expect(described_class.by_group_ids([group.id])).to contain_exactly(member1, member2, guest2)
      end
    end

    describe '.guests' do
      it 'returns only guests members' do
        expect(described_class.guests).to contain_exactly(guest1, guest2)
      end
    end

    describe '.with_saml_identity' do
      let(:saml_provider) { create :saml_provider }
      let(:group) { saml_provider.group }
      let!(:member) do
        create(:group_member, group: group).tap do |m|
          create(:group_saml_identity, saml_provider: saml_provider, user: m.user)
        end
      end

      let!(:member_without_identity) do
        create(:group_member, group: group)
      end

      let!(:member_with_different_identity) do
        create(:group_member, group: group).tap do |m|
          create(:group_saml_identity, user: m.user)
        end
      end

      it 'returns members with identity linked to given saml provider' do
        expect(described_class.with_saml_identity(saml_provider)).to eq([member])
      end
    end
  end

  context 'group member webhooks', :sidekiq_inline do
    let_it_be_with_refind(:group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:group_hook) { create(:group_hook, group: group, member_events: true) }
    let_it_be(:user) { create(:user) }

    context 'when a member is added to the group' do
      let(:group_member) { create(:group_member, group: group) }

      before do
        WebMock.stub_request(:post, group_hook.url)
      end

      it 'executes user_add_to_group event webhook' do
        group.add_guest(group_member.user)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_add_to_group')
        )
      end

      context 'ancestor groups' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:subgroup_hook) { create(:group_hook, group: subgroup, member_events: true) }

        it 'fires two webhooks when parent group has member_events webhook enabled' do
          WebMock.stub_request(:post, subgroup_hook.url)

          subgroup.add_guest(user)

          expect(WebMock).to have_requested(:post, subgroup_hook.url)
          expect(WebMock).to have_requested(:post, group_hook.url)
        end

        it 'fires one webhook when parent group has member_events webhook disabled' do
          group_hook = create(:group_hook, group: group, member_events: false)

          WebMock.stub_request(:post, subgroup_hook.url)

          subgroup.add_guest(user)

          expect(WebMock).to have_requested(:post, subgroup_hook.url)
          expect(WebMock).not_to have_requested(:post, group_hook.url)
        end
      end
    end

    context 'when a group member is updated' do
      let(:group_member) { create(:group_member, :developer, group: group, expires_at: 1.day.from_now) }

      it 'executes user_update_for_group event webhook when user role is updated' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.update!(access_level: Gitlab::Access::MAINTAINER)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_update_for_group')
        )
      end

      it 'executes user_update_for_group event webhook when user expiration date is updated' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.update!(expires_at: 2.days.from_now)

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_update_for_group')
        )
      end
    end

    context 'when the group member is deleted' do
      let_it_be(:group_member) { create(:group_member, :developer, group: group, expires_at: 1.day.from_now) }

      it 'executes user_remove_from_group event webhook when group member is deleted' do
        WebMock.stub_request(:post, group_hook.url)

        group_member.destroy!

        expect(WebMock).to have_requested(:post, group_hook.url).with(
          webhook_data(group_member, 'user_remove_from_group')
        )
      end
    end

    context 'does not execute webhook' do
      before do
        WebMock.stub_request(:post, group_hook.url)
      end

      it 'does not execute webhooks if group member events webhook is disabled' do
        group_hook = create(:group_hook, group: group, member_events: false)

        group.add_guest(user)

        expect(WebMock).not_to have_requested(:post, group_hook.url)
      end

      it 'does not execute webhooks if license is disabled' do
        stub_licensed_features(group_webhooks: false)

        group.add_guest(user)

        expect(WebMock).not_to have_requested(:post, group_hook.url)
      end
    end
  end

  context 'group member welcome email', :sidekiq_inline do
    let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }

    let(:user) { create(:user) }

    context 'when user is provisioned by group' do
      before do
        user.user_detail.update!(provisioned_by_group_id: group.id)
      end

      it 'schedules the welcome email with confirmation' do
        expect_next_instance_of(NotificationService) do |notification|
          expect(notification).to receive(:new_group_member_with_confirmation)
          expect(notification).not_to receive(:new_group_member)
        end

        group.add_developer(user)
      end
    end

    context 'when user is not provisioned by group' do
      it 'schedules plain welcome to the group email' do
        expect_next_instance_of(NotificationService) do |notification|
          expect(notification).to receive(:new_group_member)
          expect(notification).not_to receive(:new_group_member_with_confirmation)
        end

        group.add_developer(user)
      end
    end
  end

  describe '#provisioned_by_this_group?' do
    let_it_be(:group) { create(:group) }

    let(:user) { build(:user) }
    let(:member) { build(:group_member, group: group, user: user) }
    let(:invited) { build(:group_member, :invited, group: group, user: user) }

    subject { member.provisioned_by_this_group? }

    context 'when user is provisioned by the group' do
      let!(:user_detail) { build(:user_detail, user: user, provisioned_by_group_id: group.id) }

      it { is_expected.to eq(true) }
    end

    context 'when user is not provisioned by the group' do
      it { is_expected.to eq(false) }
    end

    context 'when member does not have a related user (invited member)' do
      let(:member) { invited }

      it { is_expected.to eq(false) }
    end
  end

  def webhook_data(group_member, event)
    {
      headers: { 'Content-Type' => 'application/json', 'User-Agent' => "GitLab/#{Gitlab::VERSION}", 'X-Gitlab-Event' => 'Member Hook' },
      body: {
        created_at: group_member.created_at&.xmlschema,
        updated_at: group_member.updated_at&.xmlschema,
        group_name: group.name,
        group_path: group.path,
        group_id: group.id,
        user_username: group_member.user.username,
        user_name: group_member.user.name,
        user_email: group_member.user.email,
        user_id: group_member.user.id,
        group_access: group_member.human_access,
        expires_at: group_member.expires_at&.xmlschema,
        group_plan: 'ultimate',
        event_name: event
      }.to_json
    }
  end
end
