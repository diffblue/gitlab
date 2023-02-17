# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::PreScanVerificationSteps::CreateOrUpdateService, :dynamic_analysis,
  feature_category: :dynamic_application_security_testing do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }
  let_it_be(:step) { 'connection' }
  let_it_be(:verification_errors) { [] }

  let(:params) { { step: step, verification_errors: verification_errors, verification: dast_pre_scan_verification } }

  describe '#execute' do
    subject { described_class.new(project: project, current_user: developer, params: params).execute }

    it_behaves_like 'feature security_on_demand_scans is not available'

    it_behaves_like 'when a user can not create_on_demand_dast_scan because they do not have access to a project'

    context 'when the licensed feature is available' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      it 'communicates success' do
        expect(subject.status).to eq(:success)
      end

      it 'does update the pre scan verification step' do
        expect(subject.payload[:verification_step].verification_errors).to match_array(verification_errors)
      end

      context 'when the verification.project and project does not match' do
        let_it_be(:dast_pre_scan_verification) do
          create(:dast_pre_scan_verification, dast_profile: create(:dast_profile))
        end

        it_behaves_like 'an error occurred in the execute method of dast service' do
          let(:error_message) { 'Insufficient permissions' }
        end
      end

      context 'when an error occurs' do
        let(:step) { 'invalid_step' }

        it_behaves_like 'an error occurred in the execute method of dast service' do
          let(:error_message) do
            'Error creating or updating PreScanVerificationStep: invalid_step is not a valid pre step name'
          end
        end
      end
    end
  end
end
