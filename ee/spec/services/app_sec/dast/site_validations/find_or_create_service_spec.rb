# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteValidations::FindOrCreateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_site) { create(:dast_site, project: project) }
  let_it_be(:dast_site_token) { create(:dast_site_token, project: project, url: dast_site.url) }

  let(:params) { { dast_site_token: dast_site_token, url_path: SecureRandom.hex, validation_strategy: :text_file } }

  subject { described_class.new(container: project, current_user: developer, params: params).execute }

  describe 'execute', :clean_gitlab_redis_shared_state do
    context 'when the licensed feature is available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when the licensed feature is available' do
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

      it 'attempts to validate' do
        expected_args = { project: project, current_user: developer, params: { dast_site_validation: instance_of(DastSiteValidation) } }

        expect(AppSec::Dast::SiteValidations::RunnerService).to receive(:new).with(expected_args).and_call_original

        subject
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

      context 'when the site has already passed validation' do
        let_it_be(:dast_site_validation) { create(:dast_site_validation, dast_site_token: dast_site_token, state: :passed) }

        it 'returns the existing dast_site_validation' do
          expect(subject.payload).to eq(dast_site_validation)
        end

        it 'does not create a new record in the database' do
          expect { subject }.not_to change { DastSiteValidation.count }
        end

        it 'does not attempt to re-validate' do
          expect(AppSec::Dast::SiteValidations::RunnerService).not_to receive(:new)

          subject
        end

        it 'associates the dast_site_validation with the dast_site' do
          expect(subject.payload).to eq(dast_site.reload.dast_site_validation)
        end
      end
    end
  end
end
