# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting do
  let(:group) { create(:group) }
  let(:setting) { group.namespace_settings }

  describe 'validations' do
    subject(:settings) { group.namespace_settings }

    it { is_expected.to validate_presence_of(:unique_project_download_limit) }
    it { is_expected.to validate_presence_of(:unique_project_download_limit_interval_in_seconds) }
    it {
      is_expected.to validate_numericality_of(:unique_project_download_limit)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(10_000)
    }
    it {
      is_expected.to validate_numericality_of(:unique_project_download_limit_interval_in_seconds)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(10.days.to_i)
    }
  end

  describe '#prevent_forking_outside_group?' do
    context 'with feature available' do
      before do
        stub_licensed_features(group_forking_protection: true)
      end

      context 'group with no associated saml provider' do
        before do
          setting.update!(prevent_forking_outside_group: true)
        end

        it 'returns namespace setting' do
          expect(setting.prevent_forking_outside_group?).to eq(true)
        end
      end

      context 'group with associated saml provider' do
        before do
          stub_licensed_features(group_saml: true, group_forking_protection: true)
        end

        context 'when it is configured to true on saml level' do
          before do
            setting.update!(prevent_forking_outside_group: true)
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true, group: group)
          end

          it 'returns true' do
            expect(setting.prevent_forking_outside_group?).to eq(true)
          end
        end

        context 'when it is configured to false on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: false, group: group)
          end

          it 'returns false' do
            expect(setting.prevent_forking_outside_group?).to eq(false)
          end

          context 'when setting is configured on namespace level' do
            before do
              setting.update!(prevent_forking_outside_group: true)
            end

            it 'returns namespace setting' do
              expect(setting.prevent_forking_outside_group?).to eq(true)
            end
          end
        end
      end
    end

    context 'without feature available' do
      before do
        setting.update!(prevent_forking_outside_group: true)
      end

      it 'returns false' do
        expect(setting.prevent_forking_outside_group?).to be_falsey
      end

      context 'when saml setting is available' do
        before do
          stub_licensed_features(group_saml: true)
        end

        context 'when it is configured to true on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true, group: group)
          end

          it 'returns true' do
            expect(setting.prevent_forking_outside_group?).to eq(true)
          end
        end

        context 'when it is configured to false on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: false, group: group)
          end

          it 'returns false' do
            expect(setting.prevent_forking_outside_group?).to eq(false)
          end
        end
      end
    end
  end

  context 'validating new_user_signup_cap' do
    using RSpec::Parameterized::TableSyntax

    where(:feature_available, :old_value, :new_value, :expectation) do
      true  | nil | 10 | true
      true  | 0   | 10 | true
      true  | 0   | 0  | true
      false | nil | 10 | false
      false | 10  | 10 | true
    end

    with_them do
      let(:setting) { build(:namespace_settings, new_user_signups_cap: old_value) }
      let(:group) { create(:group, namespace_settings: setting) }

      before do
        allow(group).to receive(:user_cap_available?).and_return feature_available

        setting.new_user_signups_cap = new_value
      end

      it 'returns the expected response' do
        expect(setting.valid?).to be expectation
        expect(setting.errors.messages[:new_user_signups_cap]).to include("cannot be enabled") unless expectation
      end
    end

    context 'when enabling the setting' do
      let(:feature_available) { true }

      before do
        allow(group).to receive(:user_cap_available?).and_return feature_available

        setting.new_user_signups_cap = 10
      end

      shared_examples 'user cap is not available' do
        it 'is invalid' do
          expect(setting.valid?).to be false
          expect(setting.errors.messages[:new_user_signups_cap]).to include("cannot be enabled")
        end
      end

      context 'when the group is a subgroup' do
        before do
          group.parent = build(:group)
        end

        it_behaves_like 'user cap is not available'
      end

      context 'when the group is shared externally' do
        before do
          create(:group_group_link, shared_group: group)
        end

        it_behaves_like 'user cap is not available'
      end

      context 'when the namespace is a user' do
        let(:user) { create(:user) }
        let(:setting) { user.namespace.namespace_settings }

        it_behaves_like 'user cap is not available'
      end
    end
  end

  context 'hooks related to group user cap update' do
    let(:group) { create(:group) }
    let(:settings) { group.namespace_settings }

    before do
      allow(group).to receive(:root?).and_return(true)
      allow(group).to receive(:user_cap_available?).and_return(true)

      group.namespace_settings.update!(new_user_signups_cap: user_cap)
    end

    context 'when updating a group with a user cap' do
      let(:user_cap) { nil }

      it 'also sets share_with_group_lock and prevent_sharing_groups_outside_hierarchy to true' do
        expect(group.new_user_signups_cap).to be_nil
        expect(group.share_with_group_lock).to be_falsey
        expect(settings.prevent_sharing_groups_outside_hierarchy).to be_falsey

        settings.update!(new_user_signups_cap: 10)
        group.reload

        expect(group.new_user_signups_cap).to eq(10)
        expect(group.share_with_group_lock).to be_truthy
        expect(settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end

      it 'has share_with_group_lock and prevent_sharing_groups_outside_hierarchy returning true for descendent groups' do
        descendent = create(:group, parent: group)
        desc_settings = descendent.namespace_settings

        expect(descendent.share_with_group_lock).to be_falsey
        expect(desc_settings.prevent_sharing_groups_outside_hierarchy).to be_falsey

        settings.update!(new_user_signups_cap: 10)

        expect(descendent.reload.share_with_group_lock).to be_truthy
        expect(desc_settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end
    end

    context 'when removing a user cap from namespace settings' do
      let(:user_cap) { 10 }

      it 'leaves share_with_group_lock and prevent_sharing_groups_outside_hierarchy set to true to the related group' do
        expect(group.share_with_group_lock).to be_truthy
        expect(settings.prevent_sharing_groups_outside_hierarchy).to be_truthy

        settings.update!(new_user_signups_cap: nil)

        expect(group.reload.share_with_group_lock).to be_truthy
        expect(settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end
    end
  end

  describe '.parameters' do
    it 'includes attributes used for limiting unique project downloads' do
      expect(described_class.allowed_namespace_settings_params).to include(*%i[
        unique_project_download_limit
        unique_project_download_limit_interval_in_seconds
      ])
    end
  end
end
