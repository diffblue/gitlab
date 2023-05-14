# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::ComplianceFramework::GroupSettingsHelper, feature_category: :compliance_management do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:current_user) { build(:admin) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    stub_licensed_features(compliance_pipeline_configuration: true)
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
        [:group_path, group.full_path],
        [:can_add_edit, 'true'],
        [:pipeline_configuration_full_path_enabled, 'true'],
        [:pipeline_configuration_enabled, 'true'],
        [:graphql_field_name, ComplianceManagement::Framework.name]
      )
    end

    context 'with out access to pipeline_configuration_enabled feature' do
      before do
        stub_licensed_features(compliance_pipeline_configuration: false)
      end

      it {
        is_expected.to include(pipeline_configuration_enabled: "false")
      }
    end

    context 'group is a subgroup' do
      let_it_be(:group) { create(:group, :nested) }

      it 'contains the root ancestor as group_path' do
        expect(subject[:group_path]).to eq(group.root_ancestor.full_path)
      end

      it 'does not allow editing' do
        expect(subject[:can_add_edit]).to eq('false')
      end
    end
  end
end
