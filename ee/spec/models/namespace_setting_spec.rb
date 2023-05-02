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

    describe 'unique_project_download_limit_allowlist', feature_category: :insider_threat do
      let_it_be(:user) { create(:user) }

      let(:attr) { :unique_project_download_limit_allowlist }

      it { is_expected.to allow_value([]).for(attr) }
      it { is_expected.to allow_value([user.username]).for(attr) }
      it { is_expected.not_to allow_value(nil).for(attr) }
      it { is_expected.not_to allow_value(['unknown_user']).for(attr) }

      context 'when maximum length is exceeded' do
        it 'is not valid' do
          subject.unique_project_download_limit_allowlist = generate_list(:username, 101)

          expect(subject).not_to be_valid
          expect(subject.errors[attr]).to include("exceeds maximum length (100 usernames)")
        end
      end

      describe 'AI related settings' do
        subject(:settings) { group.namespace_settings }

        shared_examples 'AI related settings validations' do |attr|
          before do
            allow(subject).to receive(:ai_settings_allowed?).and_return(true)
          end

          it { is_expected.to allow_value(false).for(attr) }
          it { is_expected.to allow_value(true).for(attr) }
          it { is_expected.not_to allow_value(nil).for(attr) }

          context 'when AI settings are not allowed' do
            before do
              allow(subject).to receive(:ai_settings_allowed?).and_return(false)
            end

            it "#{attr} is not valid" do
              subject[attr] = !subject[attr]

              expect(subject).not_to be_valid
              expect(subject.errors[attr].first).to include("settings not allowed.")
            end
          end
        end

        it_behaves_like 'AI related settings validations', :third_party_ai_features_enabled
        it_behaves_like 'AI related settings validations', :experiment_features_enabled
      end
    end

    describe 'unique_project_download_limit_alertlist', feature_category: :insider_threat do
      let_it_be(:user) { create(:user) }

      let(:attr) { :unique_project_download_limit_alertlist }

      it { is_expected.to allow_value([]).for(attr) }
      it { is_expected.to allow_value([user.id]).for(attr) }
      it { is_expected.to allow_value(nil).for(attr) }
      it { is_expected.not_to allow_value([non_existing_record_id]).for(attr) }

      context 'when maximum length is exceeded' do
        it 'is not valid' do
          subject.unique_project_download_limit_alertlist = Array.new(101)

          expect(subject).not_to be_valid
          expect(subject.errors[attr]).to include('exceeds maximum length (100 user ids)')
        end

        context 'when empty' do
          let(:active_user) { create(:user) }
          let(:inactive_user) { create(:user, :deactivated) }

          before do
            group.add_owner(active_user)
            group.add_owner(inactive_user)
          end

          it 'returns the user ids of the active group owners' do
            expect(subject.unique_project_download_limit_alertlist).to contain_exactly(active_user.id)
          end
        end

        context 'when not empty' do
          let(:alerted_user_ids) { [1, 2] }

          before do
            subject.update_attribute(:unique_project_download_limit_alertlist, alerted_user_ids)
          end

          it 'returns the set user ids' do
            expect(subject.unique_project_download_limit_alertlist).to eq(alerted_user_ids)
          end
        end
      end
    end
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

  describe '.allowed_namespace_settings_params' do
    it 'includes attributes used for limiting unique project downloads' do
      expect(described_class.allowed_namespace_settings_params).to include(
        *%i[
          unique_project_download_limit
          unique_project_download_limit_interval_in_seconds
          unique_project_download_limit_allowlist
        ])
    end
  end

  describe '.cascading_with_parent_namespace' do
    context "when calling .cascading_with_parent_namespace" do
      it 'create three instance methods for attribute' do
        described_class.cascading_with_parent_namespace("any_configuration")
        expect(described_class.instance_methods).to include(
          :any_configuration_of_parent_group, :any_configuration_locked?, :any_configuration?)
      end
    end

    context 'three configurations of MR checks' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
      let_it_be_with_reload(:subsubgroup) { create(:group, parent: subgroup) }

      shared_examples '[configuration](inherit_group_setting: bool) and [configuration]_locked?' do |attribute|
        using RSpec::Parameterized::TableSyntax

        where(:group_attr, :subgroup_attr, :subsubgroup_attr, :group_with_inherit_attr?, :group_without_inherit_attr?, :group_locked?, :subgroup_with_inherit_attr?, :subgroup_without_inherit_attr?, :subgroup_locked?, :subsubgroup_with_inherit_attr?, :subsubgroup_without_inherit_attr?, :subsubgroup_locked?) do
          true  | true  | true      | true  | true  | false     | true  | true  | true      | true  | true  | true
          true  | true  | false     | true  | true  | false     | true  | true  | true      | true  | false | true
          true  | false | false     | true  | true  | false     | true  | false | true      | true  | false | true
          false | true  | true      | false | false | false     | true  | true  | false     | true  | true  | true
          false | true  | false     | false | false | false     | true  | true  | false     | true  | false | true
          false | false | false     | false | false | false     | false | false | false     | false | false | false
        end

        with_them do
          before do
            group.namespace_settings.update!(attribute => group_attr)
            subgroup.namespace_settings.update!(attribute => subgroup_attr)
            subsubgroup.namespace_settings.update!(attribute => subsubgroup_attr)
          end

          it 'returns correct value' do
            expect(group.namespace_settings.public_send("#{attribute}?", inherit_group_setting: true)).to eq(group_with_inherit_attr?)
            expect(group.namespace_settings.public_send("#{attribute}?", inherit_group_setting: false)).to eq(group_without_inherit_attr?)
            expect(group.namespace_settings.public_send("#{attribute}_locked?")).to eq(group_locked?)

            expect(subgroup.namespace_settings.public_send("#{attribute}?", inherit_group_setting: true)).to eq(subgroup_with_inherit_attr?)
            expect(subgroup.namespace_settings.public_send("#{attribute}?", inherit_group_setting: false)).to eq(subgroup_without_inherit_attr?)
            expect(subgroup.namespace_settings.public_send("#{attribute}_locked?")).to eq(subgroup_locked?)

            expect(subsubgroup.namespace_settings.public_send("#{attribute}?", inherit_group_setting: true)).to eq(subsubgroup_with_inherit_attr?)
            expect(subsubgroup.namespace_settings.public_send("#{attribute}?", inherit_group_setting: false)).to eq(subsubgroup_without_inherit_attr?)
            expect(subsubgroup.namespace_settings.public_send("#{attribute}_locked?")).to eq(subsubgroup_locked?)
          end
        end
      end

      it_behaves_like '[configuration](inherit_group_setting: bool) and [configuration]_locked?', :only_allow_merge_if_pipeline_succeeds
      it_behaves_like '[configuration](inherit_group_setting: bool) and [configuration]_locked?', :allow_merge_on_skipped_pipeline
      it_behaves_like '[configuration](inherit_group_setting: bool) and [configuration]_locked?', :only_allow_merge_if_all_discussions_are_resolved
    end
  end

  describe '.ai_settings_allowed?' do
    using RSpec::Parameterized::TableSyntax

    where(:check_namespace_plan, :main_feature_flag, :secondary_feature_flag, :licensed_feature, :is_root, :result) do
      true  | true  | true  | true  | true  | true
      false | true  | true  | true  | true  | false
      true  | false | true  | true  | true  | false
      true  | true  | false | true  | true  | false
      true  | true  | true  | false | true  | false
      true  | true  | true  | true  | false | false
    end

    with_them do
      let(:group) { create(:group) }
      subject { group.namespace_settings.ai_settings_allowed? }

      before do
        allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(check_namespace_plan)
        stub_feature_flags(openai_experimentation: main_feature_flag)
        stub_feature_flags(ai_related_settings: secondary_feature_flag)
        allow(group).to receive(:licensed_feature_available?).with(:ai_features).and_return(licensed_feature)
        allow(group).to receive(:root?).and_return(is_root)
      end

      it { is_expected.to eq result }
    end
  end
end
