# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteProfileSecretVariables::CreateOrUpdateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:developer) { create(:user, developer_projects: [project] ) }

  let_it_be(:default_params) do
    {
      dast_site_profile: dast_profile.dast_site_profile,
      key: Dast::SiteProfileSecretVariable::PASSWORD,
      raw_value: SecureRandom.hex
    }
  end

  let(:params) { default_params }

  subject { described_class.new(container: project, current_user: developer, params: params).execute }

  describe 'execute' do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to include('Insufficient permissions')
        end
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      shared_examples 'it errors when a required param is missing' do |parameter|
        context "when #{parameter} param is missing" do
          let(:params) { default_params.except(parameter) }

          it 'communicates failure', :aggregate_failures do
            expect(subject.status).to eq(:error)
            expect(subject.message).to eq("#{parameter.to_s.humanize} param is missing")
          end
        end
      end

      shared_examples 'it errors when there is a validation failure' do
        let(:params) { default_params.merge(raw_value: '') }

        it 'communicates failure', :aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to include('Value is invalid')
        end
      end

      it_behaves_like 'it errors when a required param is missing', :dast_site_profile
      it_behaves_like 'it errors when a required param is missing', :key
      it_behaves_like 'it errors when a required param is missing', :raw_value
      it_behaves_like 'it errors when there is a validation failure'

      it 'communicates success' do
        expect(subject.status).to eq(:success)
      end

      it 'creates a dast_site_profile_secret_variable', :aggregate_failures do
        expect { subject }.to change { Dast::SiteProfileSecretVariable.count }.by(1)

        expect(subject.payload.value).to eq(Base64.strict_encode64(params[:raw_value]))
      end

      context 'when a variable already exists' do
        let_it_be(:dast_site_profile_secret_variable) do
          create(:dast_site_profile_secret_variable, key: default_params[:key], dast_site_profile: dast_profile.dast_site_profile)
        end

        let(:params) { default_params.merge(raw_value: 'hello, world') }

        it_behaves_like 'it errors when there is a validation failure'

        it 'does not create a dast_site_profile_secret_variable' do
          expect { subject }.not_to change { Dast::SiteProfileSecretVariable.count }
        end

        it 'updates the existing dast_site_profile_secret_variable' do
          subject

          expect(dast_site_profile_secret_variable.reload.value).to eq(Base64.strict_encode64(params[:raw_value]))
        end
      end
    end
  end
end
