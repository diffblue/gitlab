# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifact do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  describe '#save_verification_details' do
    let(:verifiable_model_record) { build(:ci_job_artifact, :trace) }
    let(:verification_state_table_class) { verifiable_model_record.class.verification_state_table_class }

    context 'when direct upload is enabled for trace artifacts' do
      before do
        stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true)
      end

      it 'does not create verification details' do
        expect { verifiable_model_record.save! }.not_to change { verification_state_table_class.count }
      end
    end

    context 'when direct upload is not enabled' do
      before do
        stub_artifacts_object_storage(JobArtifactUploader, direct_upload: false)
      end

      it 'does not create verification details' do
        expect { verifiable_model_record.save! }.to change { verification_state_table_class.count }.by(1)
      end
    end
  end

  include_examples 'a replicable model with a separate table for verification state' do
    before do
      stub_artifacts_object_storage
    end

    let(:verifiable_model_record) { build(:ci_job_artifact) } # add extra params if needed to make sure the record is included in `available_verifiables`
    let(:unverifiable_model_record) { build(:ci_job_artifact, :remote_store) } # add extra params if needed to make sure the record is NOT included in `available_verifiables`
  end

  describe '#destroy' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    context 'when pipeline is destroyed' do
      it 'creates a Geo delete event async' do
        job_artifact = create(:ee_ci_job_artifact, :archive)

        payload = {
          model_record_id: job_artifact.id,
          blob_path: job_artifact.file.relative_path,
          uploader_class: 'JobArtifactUploader'
        }

        expect(::Geo::JobArtifactReplicator)
          .to receive(:bulk_create_delete_events_async)
          .with([payload])
          .once

        job_artifact.job.pipeline.destroy!
      end
    end

    context 'JobArtifact destroy fails' do
      it 'does not create a JobArtifactDeletedEvent' do
        job_artifact = create(:ee_ci_job_artifact, :archive)

        allow(job_artifact).to receive(:destroy!)
                           .and_raise(ActiveRecord::RecordNotDestroyed)

        expect { job_artifact.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
                                        .and not_change { Ci::JobArtifact.count }
      end
    end
  end

  describe '.license_scanning_reports' do
    subject { Ci::JobArtifact.license_scanning_reports }

    let_it_be(:artifact) { create(:ee_ci_job_artifact, :license_scanning) }

    it { is_expected.to eq([artifact]) }
  end

  describe '.cluster_image_scanning_reports' do
    subject { Ci::JobArtifact.cluster_image_scanning_reports }

    let_it_be(:artifact) { create(:ee_ci_job_artifact, :cluster_image_scanning) }

    it { is_expected.to eq([artifact]) }
  end

  describe '.metrics_reports' do
    subject { Ci::JobArtifact.metrics_reports }

    context 'when there is a metrics report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :metrics) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there is no metrics reports' do
      let!(:artifact) { create(:ee_ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end

  describe '.security_reports' do
    context 'when the `file_types` parameter is provided' do
      let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast) }

      subject { Ci::JobArtifact.security_reports(file_types: file_types) }

      context 'when the provided file_types is array' do
        let(:file_types) { %w(secret_detection) }

        context 'when there is a security report with the given value' do
          let!(:secret_detection_artifact) { create(:ee_ci_job_artifact, :secret_detection) }

          it { is_expected.to eq([secret_detection_artifact]) }
        end

        context 'when there are no security reports with the given value' do
          it { is_expected.to be_empty }
        end
      end

      context 'when the provided file_types is string' do
        let(:file_types) { 'secret_detection' }
        let!(:secret_detection_artifact) { create(:ee_ci_job_artifact, :secret_detection) }

        it { is_expected.to eq([secret_detection_artifact]) }
      end
    end

    context 'when the file_types parameter is not provided' do
      subject { Ci::JobArtifact.security_reports }

      context 'when there is a security report' do
        let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast) }
        let!(:secret_detection_artifact) { create(:ee_ci_job_artifact, :secret_detection) }

        it { is_expected.to match_array([sast_artifact, secret_detection_artifact]) }
      end

      context 'when there are no security reports' do
        let!(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '.coverage_fuzzing_reports' do
    subject { Ci::JobArtifact.coverage_fuzzing }

    context 'when there is a metrics report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :coverage_fuzzing) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there is no coverage fuzzing reports' do
      let!(:artifact) { create(:ee_ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end

  describe '.api_fuzzing_reports' do
    subject { Ci::JobArtifact.api_fuzzing }

    context 'when there is a metrics report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :api_fuzzing) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there is no coverage fuzzing reports' do
      let!(:artifact) { create(:ee_ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end

  describe '.sbom_reports' do
    subject { Ci::JobArtifact.sbom_reports }

    context 'when there is an sbom report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :cyclonedx) }

      it { is_expected.to match_array([artifact]) }
    end

    context 'when there is no sbom report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end

  describe '.associated_file_types_for' do
    using RSpec::Parameterized::TableSyntax

    subject { Ci::JobArtifact.associated_file_types_for(file_type) }

    where(:file_type, :result) do
      'license_scanning'    | %w(license_scanning)
      'codequality'         | %w(codequality)
      'browser_performance' | %w(browser_performance performance)
      'load_performance'    | %w(load_performance)
      'quality'             | nil
    end

    with_them do
      it { is_expected.to eq result }
    end
  end

  describe '#replicables_for_current_secondary' do
    # Selective sync is configured relative to the job artifact's project.
    #
    # Permutations of sync_object_storage combined with object-stored-artifacts
    # are tested in code, because the logic is simple, and to do it in the table
    # would quadruple its size and have too much duplication.
    where(:selective_sync_namespaces, :selective_sync_shards, :factory, :project_factory, :include_expectation) do
      nil                  | nil    | [:ci_job_artifact]           | [:project]               | true
      # selective sync by shard
      nil                  | :model | [:ci_job_artifact]           | [:project]               | true
      nil                  | :other | [:ci_job_artifact]           | [:project]               | false
      # selective sync by namespace
      :model_parent        | nil    | [:ci_job_artifact]           | [:project]               | true
      :model_parent_parent | nil    | [:ci_job_artifact]           | [:project, :in_subgroup] | true
      :other               | nil    | [:ci_job_artifact]           | [:project]               | false
      :other               | nil    | [:ci_job_artifact]           | [:project, :in_subgroup] | false
      # expired
      nil                  | nil    | [:ci_job_artifact, :expired] | [:project]               | true
    end

    with_them do
      subject(:job_artifact_included) { described_class.replicables_for_current_secondary(ci_job_artifact).exists? }

      let(:project) { create(*project_factory) } # rubocop:disable Rails/SaveBang
      let(:ci_build) { create(:ci_build, project: project) }
      let(:node) do
        create(:geo_node_with_selective_sync_for,
               model: project,
               namespaces: selective_sync_namespaces,
               shards: selective_sync_shards,
               sync_object_storage: sync_object_storage)
      end

      before do
        stub_artifacts_object_storage
        stub_current_geo_node(node)
      end

      context 'when sync object storage is enabled' do
        let(:sync_object_storage) { true }

        context 'when the job artifact is locally stored' do
          let(:ci_job_artifact) { create(*factory, job: ci_build) }

          it { is_expected.to eq(include_expectation) }
        end

        context 'when the job artifact is object stored' do
          let(:ci_job_artifact) { create(*factory, :remote_store, job: ci_build) }

          it { is_expected.to eq(include_expectation) }
        end
      end

      context 'when sync object storage is disabled' do
        let(:sync_object_storage) { false }

        context 'when the job artifact is locally stored' do
          let(:ci_job_artifact) { create(*factory, job: ci_build) }

          it { is_expected.to eq(include_expectation) }
        end

        context 'when the job artifact is object stored' do
          let(:ci_job_artifact) { create(*factory, :remote_store, job: ci_build) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#security_report' do
    let(:job_artifact) { create(:ee_ci_job_artifact, :sast) }
    let(:validate) { false }
    let(:security_report) { job_artifact.security_report(validate: validate) }

    subject(:findings_count) { security_report.findings.length }

    it { is_expected.to be(5) }

    context 'for different types' do
      where(:file_type, :security_report?) do
        :performance            | false
        :sast                   | true
        :secret_detection       | true
        :dependency_scanning    | true
        :container_scanning     | true
        :cluster_image_scanning | true
        :dast                   | true
        :coverage_fuzzing       | true
      end

      with_them do
        let(:job_artifact) { create(:ee_ci_job_artifact, file_type) }

        subject { security_report.is_a?(::Gitlab::Ci::Reports::Security::Report) }

        it { is_expected.to be(security_report?) }
      end
    end

    context 'when the parsing fails' do
      let(:job_artifact) { create(:ee_ci_job_artifact, :sast) }
      let(:errors) { security_report.errors }

      before do
        allow(::Gitlab::Ci::Parsers).to receive(:fabricate!).and_raise(:foo)
      end

      it 'returns an errored report instance' do
        expect(errors).to eql([{ type: 'ParsingError', message: 'An unexpected error happened!' }])
      end
    end

    describe 'schema validation' do
      where(:validate, :expected_validate_flag) do
        false | false
        false | false
        true  | true
        true  | true
      end

      with_them do
        let(:mock_parser) { double(:parser, parse!: true) }
        let(:expected_parser_args) { ['sast', instance_of(String), instance_of(::Gitlab::Ci::Reports::Security::Report), false, validate: expected_validate_flag] }

        before do
          allow(::Gitlab::Ci::Parsers).to receive(:fabricate!).and_return(mock_parser)
        end

        it 'calls the parser with the correct arguments' do
          security_report

          expect(::Gitlab::Ci::Parsers).to have_received(:fabricate!).with(*expected_parser_args)
        end
      end
    end
  end

  describe '#clear_security_report' do
    let(:job_artifact) { create(:ee_ci_job_artifact, :sast) }

    subject(:clear_security_report) { job_artifact.clear_security_report }

    before do
      job_artifact.security_report # Memoize first
      allow(::Gitlab::Ci::Reports::Security::Report).to receive(:new).and_call_original
    end

    it 'clears the security_report' do
      clear_security_report
      job_artifact.security_report

      # This entity class receives the call twice
      # because of the way MergeReportsService is implemented.
      expect(::Gitlab::Ci::Reports::Security::Report).to have_received(:new).twice
    end
  end
end
