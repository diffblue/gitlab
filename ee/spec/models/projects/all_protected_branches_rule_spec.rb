# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AllProtectedBranchesRule, feature_category: :source_code_management do
  let_it_be(:created_at) { Time.current.change(usec: 0) }
  let_it_be(:updated_at) { Time.current.change(usec: 0) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:approval_rule) do
    create(:approval_project_rule, project: project, created_at: created_at,
      updated_at: updated_at, applies_to_all_protected_branches: true)
  end

  subject { described_class.new(project) }

  describe '#any_rules?' do
    context 'when there are no approval rules and no status checks' do
      it 'returns false' do
        allow(subject).to receive_messages(approval_project_rules: [])

        expect(subject.any_rules?).to eq(false)
      end
    end

    context 'when there are approval rules' do
      it 'returns true' do
        expect(subject.any_rules?).to eq(true)
      end
    end
  end

  describe '#name' do
    it 'set to All protected branches' do
      expect(subject.name).to eq('All protected branches')
    end
  end

  describe '#group' do
    it 'returns nil' do
      expect(subject.group).to be_nil
    end
  end

  describe '#default_branch?' do
    it 'returns false' do
      expect(subject.default_branch?).to eq(false)
    end
  end

  describe '#matching_branches_count' do
    let_it_be(:protected_branch_1) { create(:protected_branch, name: "conflict-*", project: project) }
    let_it_be(:protected_branch_2) { create(:protected_branch, name: "conflict-binary-file", project: project) }
    let_it_be(:protected_branch_3) { create(:protected_branch, name: "feature", project: project) }

    it 'returns the overall number of protected branches' do
      expect(subject.matching_branches_count).to eq(8)

      # The matching branches count contains all branches starting with `conflict-` and the `feature` branch
      # `conflict-binary-file` is contained in the `conflict-*` protected branch
      expect(subject.matching_branches_count).to eq(
        Projects::BranchRule.new(project, protected_branch_1).matching_branches_count +
          Projects::BranchRule.new(project, protected_branch_3).matching_branches_count +
          Projects::BranchRule.new(project, protected_branch_2).matching_branches_count - 1
      )
    end
  end

  describe '#protected?' do
    it 'returns false' do
      expect(subject.protected?).to eq(false)
    end
  end

  describe '#branch_protection' do
    it 'returns nil' do
      expect(subject.branch_protection).to be_nil
    end
  end

  describe '#can_unprotect?' do
    it 'returns false' do
      expect(subject.can_unprotect?).to eq(false)
    end
  end

  describe '#created_at' do
    it 'returns timestamp when the first approval rule was created' do
      expect(subject.created_at).to eq(created_at)
    end
  end

  describe '#updated_at?' do
    it 'returns timestamp when the most recent approval rule was updated' do
      expect(subject.updated_at).to eq(updated_at)
    end
  end

  describe '#approval_project_rules' do
    let_it_be(:protected_branch) do
      rule = create(:approval_project_rule, project: project)
      create(:protected_branch, project: project, approval_project_rules: [rule])
    end

    let_it_be(:all_branches_approval_rule) do
      create(:approval_project_rule, project: project)
    end

    it 'returns only rules that do not belong to a protected branch' do
      expect(subject.approval_project_rules).to eq([approval_rule])
    end
  end

  describe '#external_status_checks' do
    it 'is empty' do
      expect(subject.external_status_checks).to eq([])
    end
  end
end
