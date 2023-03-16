# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::StoreScansWorker, feature_category: :vulnerability_management do
  let_it_be(:sast_scan) { create(:security_scan, scan_type: :sast) }
  let_it_be(:pipeline) { sast_scan.pipeline }
  let_it_be(:sast_build) { pipeline.security_scans.sast.last&.build }

  describe '#perform' do
    subject(:run_worker) { described_class.new.perform(pipeline.id) }

    before do
      allow(Security::StoreScansService).to receive(:execute)
      allow_next_found_instance_of(Ci::Pipeline) do |record|
        allow(record).to receive(:can_store_security_reports?).and_return(can_store_security_reports)
      end
    end

    context 'when security reports can not be stored for the pipeline' do
      let(:can_store_security_reports) { false }

      it 'does not call `Security::StoreScansService`' do
        run_worker

        expect(Security::StoreScansService).not_to have_received(:execute)
      end

      it_behaves_like 'does not record an onboarding progress action'
    end

    context 'when security reports can be stored for the pipeline' do
      let(:can_store_security_reports) { true }

      it 'calls `Security::StoreScansService`' do
        run_worker

        expect(Security::StoreScansService).to have_received(:execute)
      end

      scan_types_actions = {
        "sast" => :security_scan_enabled,
        "dependency_scanning" => :secure_dependency_scanning_run,
        "container_scanning" => :secure_container_scanning_run,
        "dast" => :secure_dast_run,
        "secret_detection" => :secure_secret_detection_run,
        "coverage_fuzzing" => :secure_coverage_fuzzing_run,
        "api_fuzzing" => :secure_api_fuzzing_run,
        "cluster_image_scanning" => :secure_cluster_image_scanning_run
      }.freeze

      scan_types_actions.each do |scan_type, action|
        context "security #{scan_type}" do
          let_it_be(:scan) { create(:security_scan, scan_type: scan_type) }
          let_it_be(:pipeline) { scan.pipeline }

          it_behaves_like 'records an onboarding progress action', [action] do
            let(:namespace) { pipeline.project.namespace }
          end
        end
      end
    end
  end
end
