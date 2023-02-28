# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillComplianceViolations, :migration,
  feature_category: :compliance_management do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:migration_attrs) do
    {
      start_id: merge_requests_compliance_violations.minimum(:id),
      end_id: merge_requests_compliance_violations.maximum(:id),
      batch_table: :merge_requests_compliance_violations,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_metrics) { table(:merge_request_metrics) }
  let(:merge_requests_compliance_violations) { table(:merge_requests_compliance_violations) }

  let!(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let!(:namespace) { namespaces.create!(name: 'root-group', path: 'root-group', type: 'Group') }

  let!(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, name: 'Alpha Gamma',
      path: 'alpha-gamma')
  end

  let!(:mr_1) do
    merge_requests.create!(title: "MR 1", source_branch: 'feat-1', target_branch: "main", target_project_id: project.id)
  end

  let!(:mr_2) do
    merge_requests.create!(title: "MR 2", source_branch: 'feat-2', target_branch: "master",
      target_project_id: project.id)
  end

  let!(:mr_3) do
    merge_requests.create!(title: "MR 3", source_branch: 'feat-3', target_branch: "trunk",
      target_project_id: project.id)
  end

  let!(:mr_4) do
    merge_requests.create!(title: "MR 4", source_branch: 'feat-4', target_branch: "develop",
      target_project_id: project.id)
  end

  let!(:mr_metrics_1) do
    merge_request_metrics.create!(merge_request_id: mr_1.id, merged_at: '2023-01-01 01:10:00+00',
      target_project_id: project.id)
  end

  let!(:mr_metrics_2) do
    merge_request_metrics.create!(merge_request_id: mr_2.id, merged_at: '2023-01-02 02:12:00+00',
      target_project_id: project.id)
  end

  let!(:mr_metrics_3) do
    merge_request_metrics.create!(merge_request_id: mr_3.id, merged_at: '2023-01-03 04:40:00+00',
      target_project_id: project.id)
  end

  let!(:mr_metrics_4) do
    merge_request_metrics.create!(merge_request_id: mr_4.id, merged_at: '2023-01-04 03:30:00+00',
      target_project_id: project.id)
  end

  let!(:mr_violation_1) do
    merge_requests_compliance_violations.create!(merge_request_id: mr_1.id, reason: 'approved_by_insufficient_users',
      severity_level: 'high', violating_user_id: user.id)
  end

  let!(:mr_violation_2) do
    merge_requests_compliance_violations.create!(merge_request_id: mr_2.id, reason: 'approved_by_merge_request_author',
      severity_level: 'high', violating_user_id: user.id)
  end

  let!(:mr_violation_3) do
    merge_requests_compliance_violations.create!(merge_request_id: mr_3.id, reason: 'approved_by_committer',
      severity_level: 'high', violating_user_id: user.id)
  end

  let!(:mr_violation_4) do
    merge_requests_compliance_violations.create!(merge_request_id: mr_4.id, reason: 'approved_by_insufficient_users',
      severity_level: 'high', violating_user_id: user.id)
  end

  subject(:perform_migration) { described_class.new(**migration_attrs).perform }

  it 'migrates data from merge_requests and merge_request_metrics into compliance violations table' do
    expect(merge_requests_compliance_violations.find(mr_violation_1.id)).to have_attributes(old_attributes)
    expect(merge_requests_compliance_violations.find(mr_violation_2.id)).to have_attributes(old_attributes)
    expect(merge_requests_compliance_violations.find(mr_violation_3.id)).to have_attributes(old_attributes)
    expect(merge_requests_compliance_violations.find(mr_violation_4.id)).to have_attributes(old_attributes)

    perform_migration

    expect(merge_requests_compliance_violations.find(mr_violation_1.id)).to have_attributes(migrated_attributes(
      mr_1.id, mr_metrics_1.id))
    expect(merge_requests_compliance_violations.find(mr_violation_2.id)).to have_attributes(migrated_attributes(
      mr_2.id, mr_metrics_2.id))
    expect(merge_requests_compliance_violations.find(mr_violation_3.id)).to have_attributes(migrated_attributes(
      mr_3.id, mr_metrics_3.id))
    expect(merge_requests_compliance_violations.find(mr_violation_4.id)).to have_attributes(migrated_attributes(
      mr_4.id, mr_metrics_4.id))
  end

  def old_attributes
    {
      title: nil,
      target_branch: nil,
      target_project_id: nil,
      merged_at: nil
    }
  end

  def migrated_attributes(merge_request_id, merge_request_metrics_id)
    merge_request = merge_requests.find(merge_request_id)
    mr_metrics = merge_request_metrics.find(merge_request_metrics_id)

    {
      title: merge_request.title,
      target_branch: merge_request.target_branch,
      target_project_id: merge_request.target_project_id,
      merged_at: mr_metrics.merged_at
    }
  end
end
