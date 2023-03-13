# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScanSecurityReportSecretsWorker, feature_category: :secret_detection do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    shared_context 'when pipeline has revocable keys' do
      let(:category) { 'secret_detection' }
      let(:file) { 'aws-key1.py' }
      let(:api_key) { 'AKIAIOSFODNN7EXAMPLE' }
      let(:identifier_name) { 'Gitleaks rule ID AWS' }
      let(:identifier_type) { 'gitleaks_rule_id' }
      let(:identifier_value) { 'AWS' }
      let(:revocation_key_type) { 'gitleaks_rule_id_aws' }

      let(:build) { create(:ee_ci_build, :secret_detection, pipeline: pipeline) }
      let(:security_finding) do
        create(
          :security_finding,
          finding_data: {
            raw_source_code_extract: api_key,
            identifiers: [
              {
                name: identifier_name,
                external_id: identifier_value,
                external_type: identifier_type
              }
            ],
            location: {
              file: file,
              start_line: 40,
              end_line: 45
            }
          },
          scan: build.security_scans.last
        )
      end

      let(:raw_metadata) do
        {
          category: category,
          raw_source_code_extract: api_key,
          location: {
            file: file,
            start_line: 40, end_line: 45
          },
          identifiers: [
            { type: identifier_type, name: identifier_name, value: identifier_value }
          ]
        }.to_json
      end

      let(:vulnerability) do
        create(
          :vulnerabilities_finding,
          :with_secret_detection,
          project: project,
          raw_metadata: raw_metadata,
          security_findings: [security_finding]
        )
      end

      before do
        create(:vulnerabilities_finding_pipeline, finding: vulnerability, pipeline: pipeline)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [pipeline.id] }
    end

    context 'for database queries' do
      include_context 'when pipeline has revocable keys'

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new { worker.perform(pipeline.id) }

        3.times do
          finding = create(:vulnerabilities_finding,
            :with_secret_detection,
            project: project,
            raw_metadata: raw_metadata,
            security_findings: [security_finding])

          create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline)
        end

        expect { worker.perform(pipeline.id) }.not_to exceed_query_limit(control_count)
      end
    end

    context 'when revocable keys exist for the pipeline' do
      include_context 'when pipeline has revocable keys'

      it 'executes the service' do
        expect_next_instance_of(Security::TokenRevocationService) do |revocation_service|
          expect(revocation_service).to receive(:execute).and_return({ message: '', status: :success })
        end

        worker.perform(pipeline.id)
      end
    end

    context 'when no revocable keys exist for the pipeline' do
      it 'does not execute the service' do
        expect(Security::TokenRevocationService).not_to receive(:new)

        worker.perform(pipeline.id)
      end
    end

    context 'with a failure in TokenRevocationService call' do
      include_context 'when pipeline has revocable keys'

      before do
        allow_next_instance_of(Security::TokenRevocationService) do |revocation_service|
          allow(revocation_service).to receive(:execute).and_return({ message: 'This is an error', status: :error })
        end
      end

      it 'raises an error' do
        expect { worker.perform(pipeline.id) }.to raise_error('This is an error')
      end
    end
  end
end
