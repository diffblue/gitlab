# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::FrameworkPolicy do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  let_it_be_with_refind(:framework) { create(:compliance_framework, namespace: group) }

  subject { described_class.new(user, framework) }

  shared_examples 'full access to compliance framework administration' do
    it { is_expected.to be_allowed(:manage_compliance_framework) }
    it { is_expected.to be_allowed(:read_compliance_framework) }
    it { is_expected.to be_allowed(:manage_group_level_compliance_pipeline_config) }
  end

  shared_examples 'no access to compliance framework administration' do
    it { is_expected.to be_disallowed(:manage_compliance_framework) }
    it { is_expected.to be_disallowed(:read_compliance_framework) }
    it { is_expected.to be_disallowed(:manage_group_level_compliance_pipeline_config) }
  end

  context 'feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true, evaluate_group_level_compliance_pipeline: true)
    end

    context 'user is group owner' do
      before do
        group.add_owner(user)
      end

      it_behaves_like 'full access to compliance framework administration'
    end

    context 'user is not a member of the namespace' do
      let(:user) { create(:user) }

      it_behaves_like 'no access to compliance framework administration'
    end

    context 'user is an admin', :enable_admin_mode do
      let(:user) { build(:admin) }

      it_behaves_like 'full access to compliance framework administration'
    end

    context 'user is subgroup member but not the owner of the root namespace' do
      let_it_be(:user) { create(:user) }

      let(:subgroup) { create(:group, :private, parent: group) }

      before do
        group.add_developer(user)
        subgroup.add_maintainer(user)
      end

      it { is_expected.to be_allowed(:read_compliance_framework) }
      it { is_expected.to be_disallowed(:manage_compliance_framework) }
      it { is_expected.to be_disallowed(:manage_group_level_compliance_pipeline_config) }
    end
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false, evaluate_group_level_compliance_pipeline: false)
    end

    it_behaves_like 'no access to compliance framework administration'
  end
end
