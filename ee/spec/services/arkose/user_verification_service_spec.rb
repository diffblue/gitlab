# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::UserVerificationService do
  let(:session_token) { '22612c147bb418c8.2570749403' }
  let(:userid) { '1999' }
  let(:service) { Arkose::UserVerificationService.new(session_token: session_token, userid: userid) }
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

        context 'when the risk score is high' do
          let(:arkose_ec_response) { Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json'))) }

          it 'returns false' do
            allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
            expect(subject).to be_falsey
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
