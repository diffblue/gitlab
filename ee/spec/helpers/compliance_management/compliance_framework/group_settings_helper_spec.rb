# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::ComplianceFramework::GroupSettingsHelper do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:current_user) { build(:admin) }

  before do
    allow(helper).to receive(:current_user) { current_user }
  end

  describe '#show_compliance_frameworks?' do
    subject { helper.show_compliance_frameworks?(group) }

    context 'the user has permission' do
      before do
        allow(helper).to receive(:can?).with(current_user, :admin_compliance_framework, group).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'the user does not have permission' do
      context 'group is not a subgroup' do
        before do
          allow(helper).to receive(:can?).with(current_user, :admin_compliance_framework, group).and_return(false)
        end

        it { is_expected.to be false }
      end
    end
  end

  describe '#compliance_frameworks_list_data' do
    subject { helper.compliance_frameworks_list_data(group) }

    before do
      allow(helper).to receive(:can?).with(current_user, :admin_compliance_framework, group).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :admin_compliance_pipeline_configuration, group).and_return(true)
    end

    it 'returns the correct data' do
      expect(helper.compliance_frameworks_list_data(group)).to contain_exactly(
        [:empty_state_svg_path, ActionController::Base.helpers.image_path('illustrations/welcome/ee_trial.svg')],
        [:group_edit_path, edit_group_path(group, anchor: 'js-compliance-frameworks-settings')],
        [:group_path, group.full_path],
        [:add_framework_path, new_group_compliance_framework_path(group)],
        [:edit_framework_path, edit_group_compliance_framework_path(group, :id)],
        [:pipeline_configuration_full_path_enabled, 'true'],
        [:graphql_field_name, ComplianceManagement::Framework.name]
      )
    end

    context 'group is a subgroup' do
      let_it_be(:group) { create(:group, :nested) }

      it 'contains the root ancestor as group_path' do
        expect(subject[:group_path]).to eq(group.root_ancestor.full_path)
      end

      it 'does not contain the add_framework_path or edit_framework_path keys' do
        expect(subject.keys).not_to include('add_framework_path')
        expect(subject.keys).not_to include('edit_framework_path')
      end
    end
  end

  describe '#compliance_frameworks_form_data' do
    let(:framework_id) { nil }

    subject { helper.compliance_frameworks_form_data(group, framework_id) }

    shared_examples 'returns the correct data' do |pipeline_configuration_enabled|
      before do
        allow(helper).to receive(:can?).with(current_user, :admin_compliance_pipeline_configuration, group).and_return(pipeline_configuration_enabled)
      end

      it 'does not contain a framework ID' do
        is_expected.to contain_exactly(
          [:framework_id, nil],
          [:group_path, group.full_path],
          [:group_edit_path, edit_group_path(group, anchor: 'js-compliance-frameworks-settings')],
          [:graphql_field_name, ComplianceManagement::Framework.name],
          [:pipeline_configuration_full_path_enabled, pipeline_configuration_enabled.to_s]
        )
      end

      context 'with a framework ID' do
        let(:framework_id) { 12345 }

        it {
          is_expected.to contain_exactly(
            [:framework_id, framework_id],
            [:group_path, group.full_path],
            [:group_edit_path, edit_group_path(group, anchor: 'js-compliance-frameworks-settings')],
            [:graphql_field_name, ComplianceManagement::Framework.name],
            [:pipeline_configuration_full_path_enabled, pipeline_configuration_enabled.to_s]
          )
        }
      end
    end

    context 'the user has pipeline configuration permission' do
      it_behaves_like 'returns the correct data', [true]
    end

    context 'the user does not have pipeline configuration permission' do
      it_behaves_like 'returns the correct data', [false]
    end

    context 'group is a subgroup' do
      let_it_be(:group) { create(:group, :nested) }

      it 'returns the root ancestor full path as group_path' do
        allow(helper).to receive(:can?).with(current_user, :admin_compliance_pipeline_configuration, group).and_return(true)

        expect(subject[:group_path]).to eq(group.root_ancestor.full_path)
      end
    end
  end
end
