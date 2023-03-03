# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::PreScanVerificationSteps::FindOrCreateService, :dynamic_analysis,
  feature_category: :dynamic_application_security_testing do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }
  let_it_be(:step) { 'connection' }

  let(:params) { { step: step, verification: dast_pre_scan_verification } }

  describe '#execute' do
    subject { described_class.new(project: project, current_user: developer, params: params).execute }

    it_behaves_like 'feature security_on_demand_scans is not available'

    it_behaves_like 'when a user can not create_on_demand_dast_scan because they do not have access to a project'

    context 'when the licensed feature is available' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the verification step run for the first time' do
        it 'creates a new pre scan verification step record in the database' do
          expect { subject }.to change { Dast::PreScanVerificationStep.count }.by(1)
        end

        context 'when there is an error during the verification step creation' do
          let_it_be(:step) { 'invalid_step' }
          let(:error_message) do
            'Error creating or updating PreScanVerificationStep: invalid_step is not a valid pre step name'
          end

          it_behaves_like 'an error occurred in the execute method of dast service'
        end
      end

      context 'when the verification step was completed before' do
        let_it_be(:verification_step) do
          create(:dast_pre_scan_verification_step,
            check_type: 'connection',
            dast_pre_scan_verification: dast_pre_scan_verification,
            verification_errors: [])
        end

        it 'does not creates a new pre scan verification step record in the database' do
          expect { subject }.not_to change { Dast::PreScanVerificationStep.count }
        end

        it 'returns the existent pre scan verification step' do
          expect(subject.payload[:verification_step]).to eq(verification_step)
        end
      end
    end
  end
end
