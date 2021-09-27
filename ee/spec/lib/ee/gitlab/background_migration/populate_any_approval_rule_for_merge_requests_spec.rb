# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForMergeRequests, schema: 20181228175414 do
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:projects) { table(:projects) }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }
  let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }

  def create_merge_request(id, params = {})
    params.merge!(id: id,
                  target_project_id: project.id,
                  target_branch: 'master',
                  source_project_id: project.id,
                  source_branch: 'mr name',
                  title: "mr name#{id}")

    merge_requests.create!(params)
  end

  before do
    create_merge_request(2, approvals_before_merge: 2)

    # Test filtering rows with empty approvals_before_merge column
    create_merge_request(3, approvals_before_merge: nil)

    # Test filtering already migrated rows
    create_merge_request(4, approvals_before_merge: 3)
    approval_merge_request_rules.create!(id: 4,
      merge_request_id: 4, approvals_required: 3, rule_type: 4, name: ApprovalRuleLike::ALL_MEMBERS)

    # Test filtering MRs with existing rules
    create_merge_request(5, approvals_before_merge: 3)
    approval_merge_request_rules.create!(id: 5,
      merge_request_id: 5, approvals_required: 3, rule_type: 1, name: 'Regular rules')

    create_merge_request(6, approvals_before_merge: 5)

    # Test filtering rows with zero approvals_before_merge column
    create_merge_request(7, approvals_before_merge: 0)

    # Test rows with too big approvals_before_merge value
    create_merge_request(8, approvals_before_merge: 2**30)
  end

  describe '#perform' do
    it 'creates approval_merge_request_rules rows according to merge_requests' do
      expect { subject.perform(1, 8) }.to change(ApprovalMergeRequestRule, :count).by(3)

      created_rows = [
        { 'merge_request_id' => 2, 'approvals_required' => 2 },
        { 'merge_request_id' => 6, 'approvals_required' => 5 }
      ]
      existing_rows = [
        { 'merge_request_id' => 4, 'approvals_required' => 3 },
        { 'merge_request_id' => 8, 'approvals_required' => 2**15 - 1 }
      ]

      rows = approval_merge_request_rules.where(rule_type: 4).order(:id).map do |row|
        row.attributes.slice('merge_request_id', 'approvals_required')
      end

      expect(rows).to match_array(created_rows + existing_rows)
    end
  end
end
