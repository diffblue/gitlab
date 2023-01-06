# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AllBranchesRule, feature_category: :source_code_management do
  let_it_be(:created_at) { Time.current.change(usec: 0) }
  let_it_be(:updated_at) { Time.current.change(usec: 0) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:approval_rule) do
    create(:approval_project_rule, project: project, created_at: created_at + 1.day, updated_at: updated_at - 1.day)
  end

  let_it_be(:status_check) do
    create(:external_status_check, project: project, created_at: created_at, updated_at: updated_at)
  end

  subject { described_class.new(project) }

  describe '#any_rules?' do
    context 'when there are no approval rules and no status checks' do
      it 'returns false' do
        allow(subject).to receive_messages(approval_project_rules: [], external_status_checks: [])

        expect(subject.any_rules?).to eq(false)
      end
    end

    context 'when there are approval rules' do
      let_it_be(:status_check) { nil }

      it 'returns true' do
        expect(subject.any_rules?).to eq(true)
      end
    end

    context 'when there are external status rules' do
      let_it_be(:approval_rule) { nil }

      it 'returns true' do
        expect(subject.any_rules?).to eq(true)
      end
    end
  end

  describe '#name' do
    it 'set to All branches' do
      expect(subject.name).to eq('All branches')
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
    it 'returns timestamp when the first status check or approval rule was created' do
      expect(subject.created_at).to eq(created_at)
    end
  end

  describe '#updated_at?' do
    it 'returns timestamp when the most recent status check or approval rule was updated' do
      expect(subject.updated_at).to eq(updated_at)
    end
  end

  describe '#approval_project_rules' do
    let_it_be(:protected_branch) do
      rule = create(:approval_project_rule, project: project)
      create(:protected_branch, project: project, approval_project_rules: [rule])
    end

    it 'returns only rules that do not belong to a protected branch' do
      expect(subject.approval_project_rules).to eq([approval_rule])
    end
  end

  describe '#external_status_checks' do
    let_it_be(:protected_branch) do
      check = create(:external_status_check, project: project)
      create(:protected_branch, project: project, external_status_checks: [check])
    end

    it 'returns only rules that do not belong to a protected branch' do
      expect(subject.external_status_checks).to eq([status_check])
    end
  end
end
