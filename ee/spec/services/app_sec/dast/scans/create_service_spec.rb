# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Scans::CreateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile } }

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: params
    ).execute
  end

  shared_examples 'a service that calls AppSec::Dast::Scans::RunService' do
    it 'delegates pipeline creation to AppSec::Dast::Scans::RunService', :aggregate_failures do
      service = double(AppSec::Dast::Scans::RunService)
      response = ServiceResponse.error(message: 'Stubbed response')

      expect(AppSec::Dast::Scans::RunService).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(expected_params).and_return(response)

      subject
    end
  end

  describe 'execute' do
    context 'when on demand scan licensed feature is not available' do
      context 'when the user cannot run an on demand scan' do
        it 'communicates failure', :aggregate_failures do
          stub_licensed_features(security_on_demand_scans: false)

          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when user can run an on demand scan' do
        before do
          project.add_developer(user)
        end

        it 'communicates success' do
          expect(subject.status).to eq(:success)
        end

        it 'returns a pipeline and pipeline_url', :aggregate_failures do
          expect(subject.payload[:pipeline]).to be_a(Ci::Pipeline)
          expect(subject.payload[:pipeline_url]).to be_a(String)
        end

        it_behaves_like 'a service that calls AppSec::Dast::Scans::RunService' do
          let(:expected_params) do
            hash_including(
              dast_profile: nil,
              branch: project.default_branch,
              ci_configuration: kind_of(String)
            )
          end
        end

        context 'when a branch is specified' do
          context 'when the branch does not exist' do
            let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch: 'other-branch' } }

            it 'responds with error message', :aggregate_failures do
              expect(subject).not_to be_success
              expect(subject.message).to eq('Reference not found')
            end
          end

          context 'when the branch exists' do
            let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch: 'orphaned-branch' } }

            it 'communicates success' do
              expect(subject.status).to eq(:success)
            end
          end
        end

        context 'when dast_scanner_profile is nil' do
          let(:dast_scanner_profile) { nil }

          it 'communicates success' do
            expect(subject.status).to eq(:success)
          end
        end

        context 'when dast_profile is specified' do
          let_it_be(:dast_profile) { create(:dast_profile, project: project) }

          let(:params) { { dast_profile: dast_profile } }

          it 'communicates success' do
            expect(subject.status).to eq(:success)
          end

          it_behaves_like 'a service that calls AppSec::Dast::Scans::RunService' do
            let(:expected_params) { hash_including(dast_profile: dast_profile) }
          end
        end

        context 'when target is not validated and an active scan is requested' do
          let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, scan_type: 'active') }

          it 'communicates failure', :aggregate_failures do
            expect(subject.status).to eq(:error)
            expect(subject.message).to eq('Cannot run active scan against unvalidated target')
          end
        end
      end
    end
  end
end
