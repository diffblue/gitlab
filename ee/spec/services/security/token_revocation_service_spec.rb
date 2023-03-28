# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TokenRevocationService, '#execute', feature_category: :security_policy_management do
  let_it_be(:revocation_token_types_url) { 'https://myhost.com/api/v1/token_types' }
  let_it_be(:token_revocation_url) { 'https://myhost.com/api/v1/revoke' }

  let_it_be(:revocable_keys) do
    [{
      'type': 'aws_key_id',
      'token': 'AKIASOMEAWSACCESSKEY',
      'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     },
     {
        'type': 'aws_secret',
        'token': 'some_aws_secret_key_some_aws_secret_key_',
        'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     },
     {
        'type': 'aws_secret',
        'token': 'another_aws_secret_key_another_secret_key',
        'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     }]
  end

  let_it_be(:revocable_external_token_types) do
    { 'types': %w(aws_key_id aws_secret gcp_key_id gcp_secret) }
  end

  subject { described_class.new(revocable_keys: revocable_keys).execute }

  before do
    stub_application_setting(secret_detection_revocation_token_types_url: revocation_token_types_url)
    stub_application_setting(secret_detection_token_revocation_token: 'token1')
    stub_application_setting(secret_detection_token_revocation_url: token_revocation_url)
  end

  context 'when revoking a glpat token' do
    let_it_be(:glpat_token) { create(:personal_access_token) }

    let_it_be(:vulnerability) do
      double('Vulnerability') # rubocop:disable RSpec/VerifiedDoubles
    end

    let_it_be(:revocable_keys) do
      [
        {
          'type': 'gitleaks_rule_id_gitlab_personal_access_token',
          'token': glpat_token.token,
          'location': 'https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile1.java#L21',
          'vulnerability': vulnerability
        },
        {
          'type': 'gitleaks_rule_id_gitlab_personal_access_token',
          'token': glpat_token.token,
          'location': 'https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile1.java#L41',
          'vulnerability': vulnerability
        }
      ]
    end

    it 'returns success' do
      expect(PersonalAccessTokens::RevokeService).to receive(:new).once.and_call_original

      audit_context = {
        name: 'personal_access_token_revoked',
        author: User.security_bot,
        scope: User.security_bot,
        target: glpat_token.user,
        message: "Revoked personal access token with id #{glpat_token.id}"
      }

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original

      expect(SystemNoteService)
        .to receive(:change_vulnerability_state)
        .with(
          vulnerability,
          User.security_bot,
          s_("TokenRevocation|This Personal Access Token has been automatically revoked on detection. " \
             "Consider investigating and rotating before marking this vulnerability as resolved.")
        )

      expect(subject[:status]).to be(:success)
    end

    context 'when vulnerability is missing' do
      before do
        revocable_keys.each do |key|
          key.delete(:vulnerability)
        end
      end

      it 'does not call `SystemNoteService`' do
        expect(SystemNoteService).not_to receive(:change_vulnerability_state)

        subject
      end
    end
  end

  context 'when revocation token API returns a response with failure' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_revoke_token_api_with_failure
      stub_revocation_token_types_api_with_success
    end

    it 'returns error' do
      expect(subject[:status]).to be(:error)
      expect(subject[:message]).to eql('Failed to revoke tokens')
    end
  end

  context 'when revocation token types API returns empty list of types' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_invalid_token_types_api_with_success
    end

    specify { expect(subject).to eql({ status: :success }) }
  end

  context 'when external revocation service is disabled' do
    specify { expect(subject).to eql({ status: :success }) }
  end

  context 'when external revocation service is enabled' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_revoke_token_api_with_success
    end

    context 'with a list of valid token types' do
      before do
        stub_revocation_token_types_api_with_success
      end

      context 'when there is a list of tokens to be revoked' do
        specify { expect(subject[:status]).to be(:success) }
      end

      context 'when token_revocation_url is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:token_revocation_url) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation token data', status: :error }) }
      end

      context 'when token_types_url is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:token_types_url) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation token data', status: :error }) }
      end

      context 'when revocation_api_token is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:revocation_api_token) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation token data', status: :error }) }
      end

      context 'when there is no token to be revoked' do
        let_it_be(:revocable_external_token_types) do
          { 'types': %w() }
        end

        specify { expect(subject).to eql({ status: :success }) }
      end
    end

    context 'when revocation token types API returns an unsuccessful response' do
      before do
        stub_revocation_token_types_api_with_failure
      end

      specify { expect(subject).to eql({ message: 'Failed to get revocation token types', status: :error }) }
    end
  end

  def stub_revoke_token_api_with_success
    stub_request(:post, token_revocation_url)
      .with(body: revocable_keys.to_json)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revoke_token_api_with_failure
    stub_request(:post, token_revocation_url)
      .with(body: revocable_keys.to_json)
      .to_return(
        status: 400,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revocation_token_types_api_with_success
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: revocable_external_token_types.to_json
      )
  end

  def stub_invalid_token_types_api_with_success
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revocation_token_types_api_with_failure
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 400,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end
end
