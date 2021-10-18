# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForProjects, schema: 20181228175414 do
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:projects) { table(:projects) }
  let(:approval_project_rules) { table(:approval_project_rules) }

  def create_project(id, params = {})
    params.merge!(id: id, namespace_id: namespace.id)

    projects.create!(params)
  end

  before do
    create_project(2, approvals_before_merge: 2)

    # Test filtering rows with empty approvals_before_merge column
    create_project(3, approvals_before_merge: 0)

    # Test filtering already migrated rows
    project_with_any_approver_rule = create_project(4, approvals_before_merge: 3)
    approval_project_rules.create!(id: 4,
      project_id: project_with_any_approver_rule.id,
      approvals_required: 3,
      rule_type: ApprovalProjectRule.rule_types[:any_approver],
      name: ApprovalRuleLike::ALL_MEMBERS)

    # Test filtering MRs with existing rules
    project_with_regular_rule = create_project(5, approvals_before_merge: 3)
    approval_project_rules.create!(id: 5,
      project_id: project_with_regular_rule.id,
      approvals_required: 3,
      rule_type: ApprovalProjectRule.rule_types[:regular],
      name: 'Regular rules')

    create_project(6, approvals_before_merge: 5)
    create_project(7, approvals_before_merge: 2**30)
  end

  describe '#perform' do
    it 'creates approval_project_rules rows according to projects' do
      expect { subject.perform(1, 7) }.to change(ApprovalProjectRule, :count).by(3)

      created_rows = [
        { 'project_id' => 2, 'approvals_required' => 2 },
        { 'project_id' => 6, 'approvals_required' => 5 }
      ]
      existing_rows = [
        { 'project_id' => 4, 'approvals_required' => 3 },
        { 'project_id' => 7, 'approvals_required' => 2**15 - 1 }
      ]

      rule_type = ApprovalProjectRule.rule_types[:any_approver]
      rows = approval_project_rules.where(rule_type: rule_type).order(:id).map do |row|
        row.attributes.slice('project_id', 'approvals_required')
      end

      expect(rows).to match_array(created_rows + existing_rows)
    end
  end
end
