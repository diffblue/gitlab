# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Member, type: :model do
  let_it_be(:user) { build :user }
  let_it_be(:group) { create :group }
  let_it_be(:member) { build :group_member, group: group, user: user }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:sub_group_member) { build(:group_member, group: sub_group, user: user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:project_member) { build(:project_member, project: project, user: user) }

  describe '#notification_service' do
    it 'returns a NullNotificationService instance for LDAP users' do
      member = described_class.new

      allow(member).to receive(:ldap).and_return(true)

      expect(member.__send__(:notification_service))
        .to be_instance_of(::EE::NullNotificationService)
    end
  end

  describe '#is_using_seat', :aggregate_failures do
    context 'when hosted on GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
      end

      it 'calls users check for using the gitlab_com seat method' do
        expect(user).to receive(:using_gitlab_com_seat?).with(group).once.and_return true
        expect(user).not_to receive(:using_license_seat?)
        expect(member.is_using_seat).to be_truthy
      end
    end

    context 'when not hosted on GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it 'calls users check for using the License seat method' do
        expect(user).to receive(:using_license_seat?).with(no_args).and_return true
        expect(user).not_to receive(:using_gitlab_com_seat?)
        expect(member.is_using_seat).to be_truthy
      end
    end
  end

  describe '#source_kind' do
    subject { member.source_kind }

    context 'when source is of Group kind' do
      it { is_expected.to eq('Group') }
    end

    context 'when source is of Sub group kind' do
      let(:member) { sub_group_member }

      it { is_expected.to eq('Sub group') }
    end

    context 'when source is of Project kind' do
      let(:member) { project_member }

      it { is_expected.to eq('Project') }
    end
  end

  describe '#group_saml_identity' do
    shared_examples_for 'member with group saml identity' do
      context 'without saml_provider' do
        it { is_expected.to eq nil }
      end

      context 'with saml_provider enabled' do
        let!(:saml_provider) { create(:saml_provider, group: member.group) }

        context 'when member has no connected identity' do
          it { is_expected.to eq nil }
        end

        context 'when member has connected identity' do
          let!(:group_related_identity) do
            create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
          end

          it 'returns related identity' do
            expect(group_saml_identity).to eq group_related_identity
          end
        end

        context 'when member has connected identity of different group' do
          before do
            create(:group_saml_identity, user: member.user)
          end

          it { is_expected.to eq nil }
        end
      end
    end

    shared_examples_for 'member with group saml identity on the top level' do
      let!(:saml_provider) { create(:saml_provider, group: parent_group) }

      let!(:group_related_identity) do
        create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
      end

      it 'returns related identity' do
        expect(member.group_saml_identity(root_ancestor: true)).to eq group_related_identity
      end
    end

    describe 'for group members' do
      context 'when member is in a top-level group' do
        let(:member) { create :group_member }

        subject(:group_saml_identity) { member.group_saml_identity }

        it_behaves_like 'member with group saml identity'
      end

      context 'when member is in a subgroup' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }
        let(:member) { create(:group_member, source: group) }

        it_behaves_like 'member with group saml identity on the top level'
      end
    end

    describe 'for project members' do
      context 'when project is nested in a group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, namespace: group)}
        let(:member) { create :project_member, source: project }

        subject(:group_saml_identity) { member.group_saml_identity }

        it_behaves_like 'member with group saml identity'
      end

      context 'when project is nested in a subgroup' do
        let(:parent_group) { create(:group)}
        let(:group) { create(:group, parent: parent_group) }
        let(:project) { create(:project, namespace: group)}
        let(:member) { create :project_member, source: project }

        it_behaves_like 'member with group saml identity on the top level'
      end

      context 'when project is nested in a personal namespace' do
        let(:project) { create(:project, namespace: create(:user).namespace )}
        let(:member) { create :project_member, source: project }

        it 'returns nothing' do
          expect(member.group_saml_identity(root_ancestor: true)).to be_nil
        end
      end
    end
  end
end
