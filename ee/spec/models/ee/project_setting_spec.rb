# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSetting, feature_category: :projects do
  it { is_expected.to belong_to(:push_rule) }
  it { is_expected.to validate_length_of(:product_analytics_instrumentation_key).is_at_most(255).allow_blank }

  describe '.has_vulnerabilities' do
    let_it_be(:setting_1) { create(:project_setting, :has_vulnerabilities) }
    let_it_be(:setting_2) { create(:project_setting) }

    subject { described_class.has_vulnerabilities }

    it { is_expected.to contain_exactly(setting_1) }
  end

  describe 'validations' do
    context 'when enabling only_mirror_protected_branches and mirror_branch_regex' do
      it 'is invalid' do
        project = build(:project, only_mirror_protected_branches: true )
        setting = build(:project_setting, project: project, mirror_branch_regex: 'text')

        expect(setting).not_to be_valid
      end
    end

    context 'when disable only_mirror_protected_branches and enable mirror_branch_regex' do
      let_it_be(:project) { build(:project, only_mirror_protected_branches: false) }

      it 'is valid' do
        setting = build(:project_setting, project: project, mirror_branch_regex: 'test')

        expect(setting).to be_valid
      end

      it 'is invalid with invalid regex' do
        setting = build(:project_setting, project: project, mirror_branch_regex: '\\')

        expect(setting).not_to be_valid
      end
    end
  end
end
