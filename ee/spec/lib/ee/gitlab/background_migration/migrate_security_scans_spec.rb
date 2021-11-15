# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::MigrateSecurityScans, schema: 20181228175414 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:security_scans) { table(:security_scans) }

  let(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:build) { builds.create! }

  subject { described_class.new }

  describe '#perform' do
    context 'when job artifacts and builds are present' do
      using RSpec::Parameterized::TableSyntax

      where(:scan_type_name, :report_type, :scan_type_number) do
        :sast | 5 | 1
        :dependency_scanning | 6 | 2
        :container_scanning | 7 | 3
        :dast | 8 | 4
      end

      with_them do
        let!(:job_artifact) do
          job_artifacts.create!(
            created_at: 10.minutes.ago,
            updated_at: 9.minutes.ago,
            project_id: project.id,
            job_id: build.id,
            file_type: report_type
          )
        end

        it 'creates a new security scan' do
          subject.perform(job_artifact.id, job_artifact.id)

          scan = Security::Scan.first
          expect(scan.build_id).to eq(build.id)
          expect(scan.scan_type).to eq(scan_type_name.to_s)
          expect(scan.created_at.to_s).to eq(job_artifact.created_at.to_s)
          expect(scan.updated_at.to_s).to eq(job_artifact.updated_at.to_s)
        end
      end
    end

    context 'job artifacts are not found' do
      it 'security scans are not created' do
        subject.perform(1, 2)

        expect(Security::Scan.count).to eq(0)
      end
    end
  end

  context 'security scan has already been saved' do
    let!(:job_artifact) { job_artifacts.create!(project_id: project.id, job_id: build.id, file_type: 5) }

    before do
      security_scans.create!(build_id: build.id, scan_type: 1)
    end

    it 'does not save a new security scan' do
      subject.perform(job_artifact.id, job_artifact.id)

      expect(Security::Scan.count).to eq(1)
    end
  end

  context 'job artifacts are not security job artifacts' do
    let!(:job_artifact) { job_artifacts.create!(project_id: project.id, job_id: build.id, file_type: 1) }

    it 'does not save a new security scan' do
      subject.perform(job_artifact.id, job_artifact.id)

      expect(Security::Scan.count).to eq(0)
    end
  end
end
