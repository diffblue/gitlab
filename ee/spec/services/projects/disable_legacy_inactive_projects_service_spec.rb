# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::DisableLegacyInactiveProjectsService do
  describe '#perform' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:active_private_project) { create_legacy_license_project(Gitlab::VisibilityLevel::PRIVATE, 1.day.ago) }
    let_it_be(:inactive_private_project) { create_legacy_license_project(Gitlab::VisibilityLevel::PRIVATE, 1.year.ago) }
    let_it_be(:active_public_project) { create_legacy_license_project(Gitlab::VisibilityLevel::PUBLIC, 1.day.ago) }
    let_it_be(:inactive_public_projects) do
      projects = []
      4.times { projects << create_legacy_license_project(Gitlab::VisibilityLevel::PUBLIC, 1.year.ago) }
      projects
    end

    before do
      stub_const("#{described_class}::UPDATE_BATCH_SIZE", 1)
      stub_const("#{described_class}::PAUSE_SECONDS", 0)
    end

    context 'when the combined batch size is more than or equal to the inactive public projects count' do
      before do
        stub_const("#{described_class}::LOOP_LIMIT", inactive_public_projects.size)
      end

      it 'disables legacy open-source license for all the public projects' do
        subject.execute

        expect(inactive_public_projects.map { |project| updated_license(project) }).to all(eq false)
        expect(updated_license(active_public_project)).to eq(true)
        expect(updated_license(inactive_private_project)).to eq(true)
        expect(updated_license(active_private_project)).to eq(true)
      end
    end

    context 'when the combined batch size is less than the inactive public projects count' do
      before do
        stub_const("#{described_class}::LOOP_LIMIT", 1)
      end

      it 'terminates the worker before completing all the projects' do
        subject.execute

        migrated_licenses = inactive_public_projects
                              .first(described_class::LOOP_LIMIT)
                              .map { |inactive_public_project| updated_license(inactive_public_project) }

        expect(migrated_licenses).to all(eq false)

        unmigrated_projects_count = inactive_public_projects.size - described_class::LOOP_LIMIT
        unmigrated_licenses = inactive_public_projects
                                .last(unmigrated_projects_count)
                                .map { |inactive_public_project| updated_license(inactive_public_project) }

        expect(unmigrated_licenses).to all(eq true)
      end
    end
  end

  def updated_license(project)
    project.project_setting.reload.legacy_open_source_license_available
  end

  def create_legacy_license_project(visibility_level, last_activity_at)
    create(:project, visibility_level: visibility_level).tap do |project|
      project.update!(last_activity_at: last_activity_at)
      create(:project_setting, project: project, legacy_open_source_license_available: true)
    end
  end
end
