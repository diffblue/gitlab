# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TargetBranchRule, feature_category: :code_review_workflow do
  it { is_expected.to belong_to(:project) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:target_branch) }

    it 'validates uniqueness of name scoped to project_id' do
      create(:target_branch_rule)

      expect(subject).to validate_uniqueness_of(:name).scoped_to(:project_id).ignoring_case_sensitivity
    end
  end

  describe '#name' do
    it 'strips name' do
      rule = described_class.new(name: '  TargetBranchRule  ')
      rule.valid?

      expect(rule.name).to eq('targetbranchrule')
    end
  end
end
