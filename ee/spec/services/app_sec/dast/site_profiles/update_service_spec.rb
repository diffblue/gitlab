# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteProfiles::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile_id) { dast_site_profile.id }

  let_it_be(:request_headers_variable) { create(:dast_site_profile_secret_variable, :request_headers, dast_site_profile: dast_site_profile) }
  let_it_be(:password_variable) { create(:dast_site_profile_secret_variable, :password, dast_site_profile: dast_site_profile) }

  let_it_be(:new_profile_name) { SecureRandom.hex }
  let_it_be(:new_target_url) { generate(:url) }
  let_it_be(:new_excluded_urls) { ["#{new_target_url}/signout"] }
  let_it_be(:new_request_headers) { "Authorization: Bearer #{SecureRandom.hex}" }
  let_it_be(:new_auth_url) { "#{new_target_url}/login" }
  let_it_be(:new_auth_password) { SecureRandom.hex }
  let_it_be(:new_auth_username) { generate(:email) }

  let(:default_params) do
    {
      id: dast_site_profile_id,
      name: new_profile_name,
      target_url: new_target_url,
      excluded_urls: new_excluded_urls,
      request_headers: new_request_headers,
      auth_enabled: true,
      auth_url: new_auth_url,
      auth_username_field: 'login[username]',
      auth_password_field: 'login[password]',
      auth_submit_field: 'css:button[type="submit_other"]',
      auth_username: new_auth_username,
      auth_password: new_auth_password
    }
  end

  let(:params) { default_params }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject do
      described_class.new(project, user).execute(**params)
    end

    let(:status) { subject.status }
    let(:message) { subject.message }
    let(:errors) { subject.errors }
    let(:payload) { subject.payload }

    context 'when a user does not have access to the project' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'updates the dast_site_profile' do
        updated_dast_site_profile = payload.reload

        expect(updated_dast_site_profile).to have_attributes(
          params.except(:request_headers, :auth_password, :target_url).merge(dast_site: have_attributes(url: new_target_url))
        )
      end

      it 'returns a dast_site_profile payload' do
        expect(payload).to be_a(DastSiteProfile)
      end

      it 'audits the update' do
        profile = payload.reload
        audit_events = AuditEvent.where(author_id: user.id)

        aggregate_failures do
          expect(audit_events.count).to be(10)

          audit_events.each do |event|
            expect(event.author).to eq(user)
            expect(event.entity).to eq(project)
            expect(event.target_id).to eq(profile.id)
            expect(event.target_type).to eq('DastSiteProfile')
            expect(event.target_details).to eq(profile.name)
          end

          custom_messages = audit_events.map(&:details).pluck(:custom_message)

          expected_custom_messages = [
            "Changed DAST site profile name from #{dast_profile.name} to #{new_profile_name}",
            "Changed DAST site profile target_url from #{dast_profile.dast_site.url} to #{new_target_url}",
            'Changed DAST site profile excluded_urls (long value omitted)',
            "Changed DAST site profile auth_url from #{dast_profile.auth_url} to #{new_auth_url}",
            "Changed DAST site profile auth_username_field from #{dast_profile.auth_username_field} to login[username]",
            "Changed DAST site profile auth_submit_field from #{dast_profile.auth_submit_field} to css:button[type=\"submit_other\"]",
            "Changed DAST site profile auth_password_field from #{dast_profile.auth_password_field} to login[password]",
            "Changed DAST site profile auth_username from #{dast_profile.auth_username} to #{new_auth_username}",
            "Changed DAST site profile auth_password (secret value omitted)",
            "Changed DAST site profile request_headers (secret value omitted)"
          ]
          expect(custom_messages).to match_array(expected_custom_messages)
        end
      end

      context 'when the target url is nil' do
        let(:params) { default_params.merge(target_url: nil) }

        it 'returns a success status' do
          expect(status).to eq(:success)
        end

        it 'does not attempt to change the associated dast_site' do
          finder = double(DastSiteProfilesFinder)

          allow(DastSiteProfilesFinder).to receive(:new).and_return(finder)
          allow(finder).to receive_message_chain(:execute, :first!).and_return(dast_site_profile)

          expect(dast_site_profile).to receive(:update!).with(hash_excluding(dast_site_profile.dast_site))

          subject
        end
      end

      context 'when the dast_site_profile doesn\'t exist' do
        let(:dast_site_profile_id) { 0 }

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('DastSiteProfile not found')
        end
      end

      context 'when excluded_urls is nil' do
        let(:params) { default_params.merge(excluded_urls: nil) }

        it 'does not change excluded_urls' do
          expect(payload.excluded_urls).to eq(dast_site_profile.excluded_urls)
        end
      end

      context 'when excluded_urls is not supplied' do
        let(:params) { default_params.except(:excluded_urls) }

        it 'does not change excluded_urls' do
          expect(payload.excluded_urls).to eq(dast_site_profile.excluded_urls)
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Insufficient permissions')
        end
      end

      shared_examples 'it handles secret variable updating' do
        it 'correctly sets the value' do
          variable = Dast::SiteProfileSecretVariable.find_by(key: key, dast_site_profile: payload)

          expect(Base64.strict_decode64(variable.value)).to eq(raw_value)
        end
      end

      shared_examples 'it handles secret variable updating failure' do
        before do
          allow_next_instance_of(AppSec::Dast::SiteProfileSecretVariables::CreateOrUpdateService) do |service|
            response = ServiceResponse.error(message: 'Something went wrong')

            allow(service).to receive(:execute).and_return(response)
          end
        end

        it 'returns an error response', :aggregate_failures do
          expect(status).to eq(:error)
          expect(message).to include('Something went wrong')
        end
      end

      shared_examples 'it handles secret variable deletion' do
        context 'when the input value is an empty string' do
          let(:params) { default_params.merge(argument => '') }

          it 'deletes the variable' do
            variable = Dast::SiteProfileSecretVariable.find_by(key: key, dast_site_profile: dast_site_profile)

            subject

            expect { variable.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when the input value is absent' do
          let(:params) { default_params.except(argument) }

          it 'does not delete the secret variable' do
            variable = Dast::SiteProfileSecretVariable.find_by(key: key, dast_site_profile: dast_site_profile)

            expect { subject }.not_to change { variable.reload.value }
          end
        end
      end

      context 'when request_headers are supplied' do
        let(:key) { 'DAST_REQUEST_HEADERS_BASE64' }
        let(:raw_value) { default_params[:request_headers] }

        it_behaves_like 'it handles secret variable updating'
        it_behaves_like 'it handles secret variable updating failure'

        it_behaves_like 'it handles secret variable deletion' do
          let(:argument) { :request_headers }
        end
      end

      context 'when auth_password is supplied' do
        let(:key) { 'DAST_PASSWORD_BASE64' }
        let(:raw_value) { default_params[:auth_password] }

        it_behaves_like 'it handles secret variable updating'
        it_behaves_like 'it handles secret variable updating failure'

        it_behaves_like 'it handles secret variable deletion' do
          let(:argument) { :auth_password }
        end
      end

      include_examples 'restricts modification if referenced by policy', :modify do
        let(:dast_profile) { dast_site_profile }
      end
    end
  end
end
