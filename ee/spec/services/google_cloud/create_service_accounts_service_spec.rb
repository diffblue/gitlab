# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::CreateServiceAccountsService do
  let(:google_oauth2_token) { 'mock-token' }
  let(:gcp_project_id) { 'mock-gcp-project-id' }

  describe '#execute' do
    before do
      stub_licensed_features(protected_environments: true)

      mock_google_oauth2_creds = Struct.new(:app_id, :app_secret)
                                       .new('mock-app-id', 'mock-app-secret')
      allow(Gitlab::Auth::OAuth::Provider)
        .to receive(:config_for)
              .with('google_oauth2')
              .and_return(mock_google_oauth2_creds)

      expect_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        mock_service_account = Struct.new(:project_id, :unique_id, :email)
                                     .new('mock-project-id', 'mock-unique-id', 'mock-email')
        expect(client)
          .to receive(:create_service_account)
                .and_return(mock_service_account)

        expect(client)
          .to receive(:create_service_account_key)
                .and_return('mock-key')

        expect(client)
          .to receive(:grant_service_account_roles)
      end
    end

    context 'when environment is new' do
      it 'creates unprotected vars' do
        project = create(:project)

        response = described_class.new(
          project,
          nil,
          google_oauth2_token: google_oauth2_token,
          gcp_project_id: gcp_project_id,
          environment_name: '*'
        ).execute

        expect(response.status).to eq(:success)
        expect(response.message).to eq('Service account generated successfully')
        expect(project.variables.count).to eq(3)
        expect(project.variables.first.protected).to eq(false)
        expect(project.variables.second.protected).to eq(false)
        expect(project.variables.third.protected).to eq(false)
      end
    end

    context 'when environment is not protected' do
      it 'creates unprotected vars' do
        project = create(:project)
        environment = create(:environment, project: project, name: 'staging')

        response = described_class.new(
          project,
          nil,
          google_oauth2_token: google_oauth2_token,
          gcp_project_id: gcp_project_id,
          environment_name: environment.name
        ).execute

        expect(response.status).to eq(:success)
        expect(response.message).to eq('Service account generated successfully')
        expect(project.variables.count).to eq(3)
        expect(project.variables.first.protected).to eq(false)
        expect(project.variables.second.protected).to eq(false)
        expect(project.variables.third.protected).to eq(false)
      end
    end

    context 'when environment is protected', :aggregate_failures do
      it 'creates protected vars' do
        project = create(:project)
        environment = create(:environment, project: project, name: 'production')
        create(:protected_environment, project: project, name: environment.name)

        response = described_class.new(
          project,
          nil,
          google_oauth2_token: google_oauth2_token,
          gcp_project_id: gcp_project_id,
          environment_name: environment.name
        ).execute

        expect(response.status).to eq(:success)
        expect(response.message).to eq('Service account generated successfully')
        expect(project.variables.count).to eq(3)
        expect(project.variables.first.protected).to eq(true)
        expect(project.variables.second.protected).to eq(true)
        expect(project.variables.third.protected).to eq(true)
      end
    end
  end
end
