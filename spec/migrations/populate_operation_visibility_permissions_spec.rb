# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe PopulateOperationVisibilityPermissions, :migration do
  let(:migration) { described_class::MIGRATION }
  let(:namespaces) { table(:namespaces) }
  let(:project_features) { table(:project_features) }
  let(:projects) { table(:projects) }

  let(:namespace) { namespaces.create!(name: 'user', path: 'user') }

  let(:proj_namespace1) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace.id) }
  let(:proj_namespace2) { namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace.id) }
  let(:proj_namespace3) { namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: namespace.id) }

  let!(:project1) { create_project('test1', proj_namespace1) }
  let!(:project2) { create_project('test2', proj_namespace2) }
  let!(:project3) { create_project('test3', proj_namespace3) }

  before do
    stub_const("#{described_class.name}::SUB_BATCH_SIZE", 2)
  end

  it 'schedules background migrations', :aggregate_failures do
      # TODO remove
      record1 = create_project_feature(project1)
      record2 = create_project_feature(project2)
      record3 = create_project_feature(project3)

      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :project_features,
        column_name: :id,
        interval: described_class::INTERVAL
      )
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end

  private

  def create_project(proj_name, proj_namespace)
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: proj_namespace.id,
      name: proj_name,
      path: proj_name
    )
  end

  def create_project_feature(project)
    project_features.create!(
      project_id: project.id,
      pages_access_level: 10
    )
  end
end
