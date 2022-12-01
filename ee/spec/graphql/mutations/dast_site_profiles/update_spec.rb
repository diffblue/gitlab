# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastSiteProfiles::Update do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }

  let(:new_profile_name) { SecureRandom.hex }
  let(:new_target_url) { generate(:url) }
  let(:new_excluded_urls) { ["#{new_target_url}/signout"] }
  let(:new_request_headers) { "Authorization: Bearer #{SecureRandom.hex}" }
  let(:new_target_type) { 'api' }
  let(:new_scan_method) { 'postman' }
  let(:new_scan_file_path) { 'https://www.domain.com/test-api-recording.har' }

  let(:new_auth) do
    {
      enabled: false,
      url: "#{new_target_url}/login",
      username_field: 'login[username]',
      password_field: 'login[password]',
      submit_field: 'css:button[type="submit_other"]',
      username: generate(:email),
      password: SecureRandom.hex
    }
  end

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        id: dast_site_profile.to_global_id,
        profile_name: new_profile_name,
        target_url: new_target_url,
        target_type: new_target_type,
        excluded_urls: new_excluded_urls,
        request_headers: new_request_headers,
        scan_method: new_scan_method,
        scan_file_path: new_scan_file_path,
        auth: new_auth
      )
    end

    context 'when on demand scan feature is enabled' do
      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it 'calls the dast_site_profile update service' do
          service = double(::AppSec::Dast::SiteProfiles::UpdateService)
          result = ServiceResponse.error(message: '')

          service_params = {
            id: dast_site_profile.id,
            name: new_profile_name,
            target_url: new_target_url,
            target_type: new_target_type,
            excluded_urls: new_excluded_urls,
            request_headers: new_request_headers,
            scan_method: new_scan_method,
            scan_file_path: new_scan_file_path,
            auth_enabled: new_auth[:enabled],
            auth_url: new_auth[:url],
            auth_username_field: new_auth[:username_field],
            auth_password_field: new_auth[:password_field],
            auth_submit_field: new_auth[:submit_field],
            auth_username: new_auth[:username],
            auth_password: new_auth[:password]
          }

          expect(::AppSec::Dast::SiteProfiles::UpdateService).to receive(:new).and_return(service)
          expect(service).to receive(:execute).with(service_params).and_return(result)

          subject
        end

        it 'updates the dast_site_profile', :aggregate_failures do
          dast_site_profile = subject[:id].find

          expect(dast_site_profile).to have_attributes(
            name: new_profile_name,
            excluded_urls: new_excluded_urls,
            auth_enabled: new_auth[:enabled],
            auth_url: new_auth[:url],
            auth_username_field: new_auth[:username_field],
            auth_password_field: new_auth[:password_field],
            auth_submit_field: new_auth[:submit_field],
            auth_username: new_auth[:username],
            scan_method: new_scan_method,
            scan_file_path: new_scan_file_path,
            dast_site: have_attributes(url: new_target_url)
          )

          expect(dast_site_profile.secret_variables.map(&:key)).to include(Dast::SiteProfileSecretVariable::REQUEST_HEADERS)
          expect(dast_site_profile.secret_variables.map(&:key)).to include(Dast::SiteProfileSecretVariable::PASSWORD)
        end

        it 'returns the complete dast_site_profile' do
          expect(subject[:dast_site_profile]).to eq(dast_site_profile)
        end

        context 'when secret variables already exist' do
          let_it_be(:request_headers_variable) { create(:dast_site_profile_secret_variable, :request_headers, dast_site_profile: dast_site_profile) }
          let_it_be(:password_variable) { create(:dast_site_profile_secret_variable, :password, dast_site_profile: dast_site_profile) }

          context 'when the arguments are omitted' do
            subject do
              mutation.resolve(
                id: dast_site_profile.to_global_id,
                profile_name: new_profile_name
              )
            end

            it 'does not delete the secret variable' do
              dast_site_profile = subject[:id].find

              expect(dast_site_profile.secret_variables).not_to be_empty
            end
          end

          context 'when the arguments are empty strings' do
            subject do
              mutation.resolve(
                id: dast_site_profile.to_global_id,
                profile_name: new_profile_name,
                request_headers: '',
                auth: { password: '' }
              )
            end

            it 'deletes secret variables' do
              dast_site_profile = subject[:id].find

              expect(dast_site_profile.secret_variables).to be_empty
            end
          end
        end

        context 'when variable creation fails' do
          it 'returns an error and the dast_site_profile' do
            service = double(AppSec::Dast::SiteProfileSecretVariables::CreateOrUpdateService)
            result = ServiceResponse.error(payload: create(:dast_site_profile), message: 'Oops')

            allow(AppSec::Dast::SiteProfileSecretVariables::CreateOrUpdateService).to receive(:new).and_return(service)
            allow(service).to receive(:execute).and_return(result)

            expect(subject).to include(errors: ['Oops'])
          end
        end
      end
    end
  end
end
