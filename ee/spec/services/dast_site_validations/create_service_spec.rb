# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteValidations::CreateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_site) { create(:dast_site, project: project) }
  let_it_be(:dast_site_token) { create(:dast_site_token, project: project, url: dast_site.url) }

  let(:params) { { dast_site_token: dast_site_token, url_path: SecureRandom.hex, validation_strategy: :text_file } }

  subject { described_class.new(container: project, current_user: developer, params: params).execute }

  shared_examples 'the licensed feature is not available' do
    it 'communicates failure' do
      stub_licensed_features(security_on_demand_scans: false)

      aggregate_failures do
        expect(subject.status).to eq(:error)
        expect(subject.message).to eq('Insufficient permissions')
      end
    end
  end

  shared_examples 'the licensed feature is available' do
    before do
      stub_licensed_features(security_on_demand_scans: true)
    end

    it 'communicates success' do
      expect(subject.status).to eq(:success)
    end

    it 'creates a new record in the database' do
      expect { subject }.to change { DastSiteValidation.count }.by(1)
    end

    it 'associates the dast_site_validation with the dast_site' do
      expect(subject.payload).to eq(dast_site.reload.dast_site_validation)
    end

    context 'when a param is missing' do
      let(:params) { { dast_site_token: dast_site_token, validation_strategy: :text_file } }

      it 'communicates failure' do
        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Key not found: :url_path')
        end
      end
    end

    context 'when the dast_site_token.project and container do not match' do
      let_it_be(:dast_site_token) { create(:dast_site_token, project: create(:project), url: dast_site.url) }

      it 'communicates failure' do
        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when the dast_site_token does not have a related dast_site via its url' do
      let_it_be(:dast_site_token) { create(:dast_site_token, project: project, url: generate(:url)) }

      it 'communicates failure' do
        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Site does not exist for profile')
        end
      end
    end
  end

  shared_examples 'a dast_site_validation already exists' do
    let!(:dast_site_validation) { create(:dast_site_validation, dast_site_token: dast_site_token, state: :passed) }

    it 'returns the existing successful dast_site_validation' do
      expect(subject.payload).to eq(dast_site_validation)
    end

    it 'does not create a new record in the database' do
      expect { subject }.not_to change { DastSiteValidation.count }
    end
  end

  describe 'execute', :clean_gitlab_redis_shared_state do
    context 'worker validation' do
      before do
        stub_feature_flags(dast_runner_site_validation: false)
      end

      it_behaves_like 'the licensed feature is not available'

      it_behaves_like 'the licensed feature is available' do
        it 'attempts to validate' do
          expect(DastSiteValidationWorker).to receive(:perform_async)

          subject
        end

        context 'when worker does not return a job id' do
          before do
            allow(DastSiteValidationWorker).to receive(:perform_async).and_return(nil)
          end

          let(:dast_site_validation) do
            DastSiteValidation.find_by!(dast_site_token: dast_site_token, url_path: params[:url_path])
          end

          it 'communicates failure' do
            aggregate_failures do
              expect(subject.status).to eq(:error)
              expect(subject.message).to eq('Validation failed')
            end
          end

          it 'sets dast_site_validation.state to failed' do
            subject

            expect(dast_site_validation.state).to eq('failed')
          end

          it 'logs an error' do
            allow(Gitlab::AppLogger).to receive(:error)

            subject

            expect(Gitlab::AppLogger).to have_received(:error).with(message: 'Unable to validate dast_site_validation', dast_site_validation_id: dast_site_validation.id)
          end
        end

        it_behaves_like 'a dast_site_validation already exists' do
          it 'does not attempt to re-validate' do
            expect(DastSiteValidationWorker).not_to receive(:perform_async)

            subject
          end
        end
      end
    end

    context 'runner validation' do
      it_behaves_like 'the licensed feature is not available'

      it_behaves_like 'the licensed feature is available' do
        it 'attempts to validate' do
          expected_args = { project: project, current_user: developer, params: { dast_site_validation: instance_of(DastSiteValidation) } }

          expect(AppSec::Dast::SiteValidations::RunnerService).to receive(:new).with(expected_args).and_call_original

          subject
        end

        it_behaves_like 'a dast_site_validation already exists' do
          it 'does not attempt to re-validate' do
            expect(AppSec::Dast::SiteValidations::RunnerService).not_to receive(:new)

            subject
          end
        end
      end
    end
  end
end
