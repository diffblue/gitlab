# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalProjectRulesProtectedBranch, feature_category: :source_code_management do
  let_it_be(:protected_branch) { create :protected_branch, name: 'main' }

  describe 'Approval project branch and protected branch join table' do
    describe '#branch_name' do
      let(:approval_rule) { create :approval_project_rule }

      it 'gives the branch name of the jointed branch' do
        instance = described_class.new(approval_project_rule: approval_rule, protected_branch: protected_branch)
        expect(instance.branch_name).to eq(protected_branch.name)
      end
    end
  end
end
