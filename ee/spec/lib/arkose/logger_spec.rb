# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::Logger do
  let(:user) { build_stubbed(:user) }
  let(:session_token) { '22612c147bb418c8.2570749403' }

  shared_examples 'logs the event with the correct payload' do |log_message|
    let(:mock_correlation_id) { 'be025cf83013ac4f52ffd2bf712b11a2' }
    let(:json_verify_response) do
      Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
    end

    let(:verify_response) { Arkose::VerifyResponse.new(json_verify_response) }
    let(:logger) { described_class.new(session_token: session_token, user: user, verify_response: verify_response) }

    let(:expected_payload) do
      {
        correlation_id: mock_correlation_id,
        message: log_message,
        response: json_verify_response,
        username: user&.username,
        'arkose.session_id': '22612c147bb418c8.2570749403',
        'arkose.global_score': '0',
        'arkose.global_telltale_list': [],
        'arkose.custom_score': '0',
        'arkose.custom_telltale_list': [],
        'arkose.risk_band': 'Low',
        'arkose.risk_category': 'NO-THREAT'
      }.compact
    end

    before do
      allow(Gitlab::AppLogger).to receive(:info)
      allow(Gitlab::ApplicationContext).to receive(:current).and_return(
        { 'correlation_id': mock_correlation_id }
      )
    end

    it 'logs the event with the correct info' do
      expect(expected_payload).to include(:username)
      expect(Gitlab::AppLogger).to receive(:info).with(expected_payload)

      subject
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'logs the event without username info' do
        expect(expected_payload).not_to include(:username)
        expect(Gitlab::AppLogger).to receive(:info).with(expected_payload)

        subject
      end
    end
  end

  describe '#log_successful_token_verification' do
    subject { logger.log_successful_token_verification }

    it_behaves_like 'logs the event with the correct payload', 'Arkose verify response'
  end

  describe '#log_unsolved_challenge' do
    subject { logger.log_unsolved_challenge }

    it_behaves_like 'logs the event with the correct payload', 'Challenge was not solved'
  end

  describe '#log_failed_token_verification' do
    subject(:logger) { described_class.new(session_token: session_token, user: user, verify_response: nil) }

    it 'logs the event with the correct info' do
      message = /Error verifying user on Arkose: {:session_token=>"#{session_token}", :log_data=>#{user.id}}/
      expect(Gitlab::AppLogger).to receive(:error).with(a_string_matching(message))

      logger.log_failed_token_verification
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'logs the event with the correct info' do
        message = /Error verifying user on Arkose: {:session_token=>"#{session_token}", :log_data=>nil}/
        expect(Gitlab::AppLogger).to receive(:error).with(a_string_matching(message))

        logger.log_failed_token_verification
      end
    end
  end
end
