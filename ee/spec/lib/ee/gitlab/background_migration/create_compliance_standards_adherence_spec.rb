# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence, :migration, schema: 20230818142801,
  feature_category: :compliance_management do
  let(:settings) { table(:application_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:approval_project_rules) { table(:approval_project_rules) }
  let(:project_compliance_standards_adherence) { table(:project_compliance_standards_adherence) }
  let(:plans) { table(:plans) }
  let(:gitlab_subscriptions) { table(:gitlab_subscriptions) }

  let!(:application_setting) do
    settings.create!(prevent_merge_requests_author_approval: false, prevent_merge_requests_committers_approval: false)
  end

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium') }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate') }

  let!(:premium_subscription) do
    gitlab_subscriptions.create!(hosted_plan_id: premium_plan.id, namespace_id: premium_group.id)
  end

  let!(:ultimate_subscription) do
    gitlab_subscriptions.create!(hosted_plan_id: ultimate_plan.id, namespace_id: ultimate_group.id)
  end

  let!(:namespace_1) { namespaces.create!(name: 'alpha', path: 'alpha', type: 'Group') }
  let!(:namespace_2) { namespaces.create!(name: 'beta', path: 'beta', type: 'Group') }
  let!(:namespace_3) { namespaces.create!(name: 'root', path: 'root', type: 'User') }
  let!(:premium_group) { namespaces.create!(name: 'premium', path: 'premium', type: 'Group') }
  let!(:ultimate_group) { namespaces.create!(name: 'ultimate', path: 'ultimate', type: 'Group') }

  let!(:project_1) do
    projects.create!(namespace_id: namespace_1.id, project_namespace_id: namespace_1.id, name: 'Project One',
      path: 'project-one', merge_requests_author_approval: false, merge_requests_disable_committers_approval: true)
  end

  let!(:project_2) do
    projects.create!(namespace_id: namespace_2.id, project_namespace_id: namespace_2.id, name: 'Project Two',
      path: 'project-two')
  end

  let!(:project_3) do
    projects.create!(namespace_id: namespace_3.id, project_namespace_id: namespace_3.id, name: 'Project Three',
      path: 'project-three')
  end

  let!(:premium_project) do
    projects.create!(namespace_id: premium_group.id, project_namespace_id: premium_group.id, name: 'Premium project',
      path: 'premium-project')
  end

  let!(:ultimate_project) do
    projects.create!(namespace_id: ultimate_group.id, project_namespace_id: ultimate_group.id, name: 'Ultimate Project',
      path: 'ultimate-project')
  end

  let!(:ultimate_project_compliance_standards_adherence) do
    project_compliance_standards_adherence.create!(created_at: '2023-08-15 00:00:00',
      updated_at: '2023-08-15 00:00:00', project_id: ultimate_project.id, namespace_id: ultimate_group.id, status: 0,
      check_name: 0, standard: 0)
  end

  let!(:project_2_approval_project_rules) do
    approval_project_rules.create!(project_id: project_2.id, approvals_required: 2, name: "All Members")
  end

  let(:migration_attrs) do
    {
      start_id: projects.minimum(:id),
      end_id: projects.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_attrs).perform }

  success_status = 0
  failed_status = 1
  prevent_approval_by_mr_author = 0
  prevent_approval_by_mr_committer = 1
  at_least_two_approvals = 2

  context 'when not GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    it 'creates standards adherence for existing projects in a group', :aggregate_failures do
      expect(project_compliance_standards_adherence.count).to eq(1)

      perform_migration

      # does not create adherence records for a project in user namespace
      expect(project_compliance_standards_adherence.count).to eq(12)
      expect(project_compliance_standards_adherence.where(project_id: project_1.id).count).to eq(3)
      expect(project_compliance_standards_adherence.where(project_id: project_2.id).count).to eq(3)
      expect(project_compliance_standards_adherence.where(project_id: project_3.id).count).to eq(0)
      expect(project_compliance_standards_adherence.where(project_id: premium_project.id).count).to eq(3)
      expect(project_compliance_standards_adherence.where(project_id: ultimate_project.id).count).to eq(3)

      # does not update the existing adherence record
      expect(project_compliance_standards_adherence.first.updated_at).to eq('2023-08-15 00:00:00')

      # creates the adherence records with correct status
      expect(project_compliance_standards_adherence.where(project_id: project_1.id).pluck(:check_name, :status))
        .to eq([
          [prevent_approval_by_mr_author, success_status],
          [prevent_approval_by_mr_committer, success_status],
          [at_least_two_approvals, failed_status]
        ])

      expect(project_compliance_standards_adherence.where(project_id: project_2.id).pluck(:check_name, :status))
        .to eq([
          [prevent_approval_by_mr_author, success_status],
          [prevent_approval_by_mr_committer, failed_status],
          [at_least_two_approvals, success_status]
        ])
    end
  end

  context 'when GitLab.com', :saas do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'creates standards adherence for existing ultimate projects in a group', :aggregate_failures do
      expect(project_compliance_standards_adherence.count).to eq(1)

      perform_migration

      # does not create adherence records for non ultimate projects
      expect(project_compliance_standards_adherence.count).to eq(3)
      expect(project_compliance_standards_adherence.where(project_id: project_1.id).count).to eq(0)
      expect(project_compliance_standards_adherence.where(project_id: project_2.id).count).to eq(0)
      expect(project_compliance_standards_adherence.where(project_id: project_3.id).count).to eq(0)
      expect(project_compliance_standards_adherence.where(project_id: premium_project.id).count).to eq(0)
      expect(project_compliance_standards_adherence.where(project_id: ultimate_project.id).count).to eq(3)

      # does not update the existing adherence record
      expect(project_compliance_standards_adherence.first.updated_at).to eq('2023-08-15 00:00:00')

      # creates the adherence records for ultimate project with correct status
      expect(project_compliance_standards_adherence.where(project_id: ultimate_project.id).pluck(:check_name, :status))
        .to eq([
          [prevent_approval_by_mr_author, success_status],
          [prevent_approval_by_mr_committer, failed_status],
          [at_least_two_approvals, failed_status]
        ])
    end
  end
end
