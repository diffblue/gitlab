# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateLatestPipelineIds do
  let(:migrator) { described_class.new }

  let(:namespaces) { table(:namespaces) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:project_settings) { table(:project_settings) }
  let(:vulnerability_statistics) { table(:vulnerability_statistics) }

  let(:letter_grade_a) { 0 }
  let(:file_types) do
    {
      sast: 5,
      dependency_scanning: 6,
      container_scanning: 7,
      dast: 8,
      secret_detection: 21,
      coverage_fuzzing: 23,
      api_fuzzing: 26
    }
  end

  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org', type: 'Group') }
  let!(:project_1) { projects.create!(namespace_id: namespace.id, name: 'Foo 1') }
  let!(:project_2) { projects.create!(namespace_id: namespace.id, name: 'Foo 2') }
  let!(:project_3) { projects.create!(namespace_id: namespace.id, name: 'Foo 3') }
  let!(:project_4) { projects.create!(namespace_id: namespace.id, name: 'Foo 4') }
  let!(:project_5) { projects.create!(namespace_id: namespace.id, name: 'Foo 5', path: 'unknown-path-to-repository') }
  let!(:project_6) { projects.create!(namespace_id: namespace.id, name: 'Foo 6') }

  let!(:project_1_pipeline) { pipelines.create!(project_id: project_1.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let!(:project_1_latest_pipeline) { pipelines.create!(project_id: project_1.id, ref: 'master', sha: 'adf43c3a', status: 'failed') }
  let!(:project_2_pipeline) { pipelines.create!(project_id: project_2.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let!(:project_2_latest_pipeline) { pipelines.create!(project_id: project_2.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let!(:project_3_pipeline) { pipelines.create!(project_id: project_3.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let!(:project_4_pipeline) { pipelines.create!(project_id: project_4.id, ref: 'master', sha: 'adf43c3a', status: 'canceled') }
  let!(:project_4_pipeline_with_wrong_status) { pipelines.create!(project_id: project_4.id, ref: 'master', sha: 'adf43c3a', status: 'running') }
  let!(:project_4_pipeline_without_security_builds) { pipelines.create!(project_id: project_4.id, ref: 'master', sha: 'adf43c3a', status: 'success') }

  let!(:project_2_stats) { vulnerability_statistics.create!(project_id: project_2.id, letter_grade: letter_grade_a, latest_pipeline_id: project_2_pipeline.id) }
  let!(:project_4_stats) { vulnerability_statistics.create!(project_id: project_4.id, letter_grade: letter_grade_a) }

  before do
    allow(::Gitlab::CurrentSettings).to receive(:default_branch_name).and_return(:master)

    project_settings.create!(project_id: project_1.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_2.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_3.id)
    project_settings.create!(project_id: project_4.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_5.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_6.id, has_vulnerabilities: true)

    # Create security builds
    create_security_build_for(project_1_pipeline, file_type: file_types[:sast])
    create_security_build_for(project_1_latest_pipeline, file_type: file_types[:dast])
    create_security_build_for(project_2_pipeline, file_type: file_types[:dependency_scanning])
    create_security_build_for(project_2_latest_pipeline, file_type: file_types[:container_scanning])
    create_security_build_for(project_3_pipeline, file_type: file_types[:secret_detection])
    create_security_build_for(project_4_pipeline, file_type: file_types[:coverage_fuzzing])
    create_security_build_for(project_4_pipeline_with_wrong_status, file_type: file_types[:coverage_fuzzing])
  end

  describe '#perform' do
    subject(:populate_latest_pipeline_ids) { migrator.perform(project_1.id, project_6.id) }

    before do
      allow(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
      allow(::Gitlab::BackgroundMigration::Logger).to receive(:info)

      # Raise a RuntimeError while retreiving the `pipeline_with_reports` for the `project_6`
      allow_next_found_instance_of(described_class::Project) do |project_instance|
        original_pipeline_with_reports = project_instance.method(:pipeline_with_reports)

        allow(project_instance).to receive(:pipeline_with_reports) do
          project_instance.id == project_6.id ? raise("Foo") : original_pipeline_with_reports.call
        end
      end
    end

    it 'sets the latest_pipeline_id' do
      expect { populate_latest_pipeline_ids }.to change { project_4_stats.reload.latest_pipeline_id }.from(nil).to(project_4_pipeline.id)
                                             .and change { vulnerability_statistics.count }.by(1)
                                             .and change { vulnerability_statistics.find_by(project_id: project_1.id) }.from(nil)
                                             .and change { vulnerability_statistics.find_by(project_id: project_1.id)&.latest_pipeline_id }.from(nil).to(project_1_latest_pipeline.id)
                                             .and not_change { project_2_stats.reload.latest_pipeline_id }.from(project_2_pipeline.id)

      expect(::Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception).once
      expect(::Gitlab::BackgroundMigration::Logger).to have_received(:info).exactly(9).times
    end
  end

  def create_security_build_for(pipeline, file_type:)
    build = builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build')

    job_artifacts.create!(project_id: pipeline.project_id, job_id: build.id, file_type: file_type, file_format: 1)
  end
end
