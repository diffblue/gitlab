# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn, :migration,
               :suppress_gitlab_schemas_validate_connection, schema: 20220326161803 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:findings) { table(:vulnerability_occurrences) }
  let(:finding_pipelines) { table(:vulnerability_occurrence_pipelines) }
  let(:builds) { table(:ci_builds) }
  let(:artifacts) { table(:ci_job_artifacts) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }

  let(:namespace) { namespaces.create!(name: "foo", path: "bar", type: "Group") }

  describe '#perform' do
    let!(:project_1) { projects.create!(namespace_id: namespace.id) }
    let!(:project_2) { projects.create!(namespace_id: namespace.id) }
    let(:utility_class) { described_class::PopulateResolvedOnDefaultBranchColumnForProject }

    subject(:populate_resolved_on_default_branch_column) { described_class.new.perform([project_1.id, project_2.id]) }

    before do
      allow(utility_class).to receive(:perform)
    end

    it 'calls `PopulateResolvedOnDefaultBranchColumnForProject.perform` for each project by given ids' do
      populate_resolved_on_default_branch_column

      expect(utility_class).to have_received(:perform).twice
      expect(utility_class).to have_received(:perform).with(project_1.id)
      expect(utility_class).to have_received(:perform).with(project_2.id)
    end
  end

  describe EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn::PopulateResolvedOnDefaultBranchColumnForProject do
    describe '.perform' do
      let(:project_id) { 1 }
      let(:mock_utility_object) { instance_double(described_class, perform: true) }

      subject(:populate_for_project) { described_class.perform(project_id) }

      before do
        allow(described_class).to receive(:new).and_return(mock_utility_object)
      end

      it 'instantiates the utility service object and calls #perform on it' do
        populate_for_project

        expect(described_class).to have_received(:new).with(project_id)
        expect(mock_utility_object).to have_received(:perform)
      end
    end

    describe '#perform' do
      let(:user) { users.create!(name: 'John Doe', email: 'test@example.com', projects_limit: 5) }
      let(:project) { projects.create!(namespace_id: namespace.id) }
      let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
      let(:utility_object) { described_class.new(project.id) }
      let(:scanner) { scanners.create!(project_id: project.id, external_id: 'bandit', name: 'Bandit') }
      let(:sha_attribute) { Gitlab::Database::ShaAttribute.new }
      let(:vulnerability_identifier) do
        vulnerability_identifiers.create!(
          project_id: project.id,
          name: 'identifier',
          fingerprint: sha_attribute.serialize('e6dd15eda2137be0034977a85b300a94a4f243a3'),
          external_type: 'bar',
          external_id: 'zoo')
      end

      let(:disappeared_vulnerability) do
        vulnerabilities.create!(
          project_id: project.id,
          author_id: user.id,
          title: 'Vulnerability',
          severity: 5,
          confidence: 5,
          report_type: 5
        )
      end

      let(:existing_vulnerability) do
        vulnerabilities.create!(
          project_id: project.id,
          author_id: user.id,
          title: 'Vulnerability',
          severity: 5,
          confidence: 5,
          report_type: 5
        )
      end

      subject(:populate_for_project) { utility_object.perform }

      before do
        build = builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build')
        artifacts.create!(project_id: project.id, job_id: build.id, file_type: 5, file_format: 1)

        finding = findings.create!(
          project_id: project.id,
          vulnerability_id: existing_vulnerability.id,
          severity: 5,
          confidence: 5,
          report_type: 5,
          scanner_id: scanner.id,
          primary_identifier_id: vulnerability_identifier.id,
          project_fingerprint: 'foo',
          location_fingerprint: sha_attribute.serialize('d869ba3f0b3347eb2749135a437dc07c8ae0f420'),
          uuid: SecureRandom.uuid,
          name: 'Solar blast vulnerability',
          metadata_version: '1',
          raw_metadata: '')

        finding_pipelines.create!(occurrence_id: finding.id, pipeline_id: pipeline.id)

        allow(::Gitlab::CurrentSettings).to receive(:default_branch_name).and_return(:master)
      end

      it 'sets `resolved_on_default_branch` attribute of disappeared vulnerabilities' do
        expect { populate_for_project }.to change { disappeared_vulnerability.reload[:resolved_on_default_branch] }.from(false).to(true)
                                       .and not_change { existing_vulnerability.reload[:resolved_on_default_branch] }
      end
    end
  end
end
