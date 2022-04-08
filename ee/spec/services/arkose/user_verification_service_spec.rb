# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::UserVerificationService do
  let(:session_token) { '22612c147bb418c8.2570749403' }
  let_it_be_with_reload(:user) { create(:user, id: '1999') }

  let(:service) { Arkose::UserVerificationService.new(session_token: session_token, user: user) }
  let(:response) { instance_double(HTTParty::Response, success?: true, code: 200, parsed_response: arkose_ec_response) }

  subject { service.execute }

  describe '#execute' do
    context 'when the user did not solve the challenge' do
      let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/failed_ec_response.json'))) }

      it 'returns false' do
        allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
        expect(subject).to be_falsey
      end
    end

    context 'when the user solved the challenge' do
      context 'when the risk score is not high' do
        let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json'))) }

        it 'returns true' do
          allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
          expect(subject).to be_truthy
        end

        it 'adds arkose data to custom attributes' do
          allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
          subject
          expect(user.custom_attributes.count).to eq(4)

          expect(user.custom_attributes.find_by(key: 'arkose_session').value).to eq('22612c147bb418c8.2570749403')
          expect(user.custom_attributes.find_by(key: 'arkose_risk_band').value).to eq('Low')
          expect(user.custom_attributes.find_by(key: 'arkose_global_score').value).to eq('0')
          expect(user.custom_attributes.find_by(key: 'arkose_custom_score').value).to eq('0')
        end

        it 'logs Arkose verify response' do
          allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
          allow(Gitlab::AppLogger).to receive(:info)
          allow(Gitlab::ApplicationContext).to receive(:current).and_return({ 'correlation_id': 'be025cf83013ac4f52ffd2bf712b11a2' })

          subject

          expect(Gitlab::AppLogger).to have_received(:info).with(correlation_id: 'be025cf83013ac4f52ffd2bf712b11a2',
                                                                 message: 'Arkose verify response',
                                                                 response: arkose_ec_response,
                                                                 username: user.username,
                                                                 'arkose.session_id': '22612c147bb418c8.2570749403',
                                                                 'arkose.global_score': '0',
                                                                 'arkose.global_telltale_list': [],
                                                                 'arkose.custom_score': '0',
                                                                 'arkose.custom_telltale_list': [],
                                                                 'arkose.risk_band': 'Low',
                                                                 'arkose.risk_category': 'NO-THREAT')
        end

        context 'when the risk score is high' do
          let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json'))) }

          it 'returns false' do
            allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
            expect(subject).to be_falsey
          end

          context 'when the session is allowlisted' do
            before do
              arkose_ec_response['session_details']['telltale_list'].push(Arkose::UserVerificationService::ALLOWLIST_TELLTALE)
            end

            it 'returns true' do
              allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
              expect(subject).to be_truthy
            end
          end
        end
      end
    end

    context 'when the response does not include the risk session' do
      context 'when the user solved the challenge' do
        let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_without_session_risk.json'))) }

        it 'returns true' do
          allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
          expect(subject).to be_truthy
        end
      end

      context 'when the user did not solve the challenge' do
        let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/failed_ec_response_without_risk_session.json'))) }

        it 'returns false' do
          allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
          expect(subject).to be_falsey
        end
      end
    end

    context 'when an error occurs during the Arkose request' do
      it 'returns true' do
        allow(Gitlab::HTTP).to receive(:perform_request).and_raise(Gitlab::HTTP::BlockedUrlError)
        expect(subject).to be_truthy
      end
    end
  end
end
