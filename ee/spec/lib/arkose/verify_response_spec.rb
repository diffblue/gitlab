# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::VerifyResponse, feature_category: :instance_resiliency do
  def parse_json(file_path)
    Gitlab::Json.parse(File.read(Rails.root.join(file_path)))
  end

  let(:invalid_token_response) do
    parse_json('ee/spec/fixtures/arkose/invalid_token.json')
  end

  let(:unsolved_challenge_response) do
    parse_json('ee/spec/fixtures/arkose/failed_ec_response.json')
  end

  let(:low_risk_response) do
    parse_json('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')
  end

  let(:high_risk_response) do
    parse_json('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json')
  end

  let(:allowlisted_response) do
    parse_json('ee/spec/fixtures/arkose/allowlisted_response.json')
  end

  describe '.new' do
    context 'when response is not a Hash' do
      it 'raises an InvalidResponseFormatError error' do
        expect { described_class.new('a_string') }.to raise_error(
          described_class::InvalidResponseFormatError,
          "Arkose Labs Verify API returned a String instead of of an object"
        )
      end
    end

    context 'when response is a Hash' do
      it 'does not raise an InvalidResponseFormatError error' do
        expect { described_class.new({}) }.not_to raise_error
      end
    end
  end

  describe '#invalid_token?' do
    subject { described_class.new(json_response).invalid_token? }

    context 'when token is invalid' do
      let(:json_response) { invalid_token_response }

      it { is_expected.to eq true }
    end

    context 'when token is valid' do
      let(:json_response) { unsolved_challenge_response }

      it { is_expected.to eq false }
    end
  end

  describe '#error' do
    let(:json_response) { invalid_token_response }

    subject { described_class.new(json_response).error }

    it { is_expected.to eq 'DENIED ACCESS' }
  end

  describe '#challenge_solved?' do
    subject { described_class.new(json_response).challenge_solved? }

    context 'when response does not contain solved data' do
      let(:json_response) { Gitlab::Json.parse("{}") }

      it { is_expected.to eq true }
    end

    context 'when response contains solved data' do
      let(:json_response) { unsolved_challenge_response }

      it { is_expected.to eq false }
    end
  end

  describe '#low_risk?' do
    subject { described_class.new(json_response).low_risk? }

    context 'when arkose_labs_prevent_login feature flag is disabled' do
      let(:json_response) { Gitlab::Json.parse("{}") }

      before do
        stub_feature_flags(arkose_labs_prevent_login: false)
      end

      it { is_expected.to eq true }
    end

    context 'when response does not contain session_risk.risk_band data' do
      let(:json_response) { Gitlab::Json.parse("{}") }

      it { is_expected.to eq true }
    end

    context 'when response contains session_risk.risk_band != "High"' do
      let(:json_response) { low_risk_response }

      it { is_expected.to eq true }
    end

    context 'when response contains session_risk.risk_band == "High"' do
      let(:json_response) { high_risk_response }

      it { is_expected.to eq false }
    end
  end

  describe '#allowlisted?' do
    subject { described_class.new(json_response).allowlisted? }

    context 'when session_details.telltale_list data includes ALLOWLIST_TELLTALE' do
      let(:json_response) { allowlisted_response }

      it { is_expected.to eq true }
    end

    context 'when session_details.telltale_list data does not include ALLOWLIST_TELLTALE' do
      let(:json_response) { high_risk_response }

      it { is_expected.to eq false }
    end

    context 'when response does not include session_details.telltale_list data' do
      let(:json_response) { Gitlab::Json.parse("{}") }

      it { is_expected.to eq false }
    end
  end

  describe 'other methods' do
    using RSpec::Parameterized::TableSyntax

    subject(:response) { described_class.new(json_response) }

    context 'when response has the correct data' do
      let(:global_telltale_list) do
        [
          { "name" => "g-h-cfp-1000000000", "weight" => "7" },
          { "name" => "g-os-impersonation-win", "weight" => "8" }
        ]
      end

      let(:custom_telltale_list) do
        [
          { "name" => "outdated-browser-customer-2", "weight" => "100" },
          { "name" => "outdated-os-customer", "weight" => "100" }
        ]
      end

      where(:method, :expected_value) do
        :custom_score         | "100"
        :global_score         | "15"
        :risk_band            | "High"
        :session_id           | "22612c147bb418c8.2570749403"
        :risk_category        | "BOT-STD"
        :global_telltale_list | lazy { global_telltale_list }
        :custom_telltale_list | lazy { custom_telltale_list }
        :device_id            | "gaFCZkxoGZYW6"
      end

      with_them do
        let(:json_response) { high_risk_response }

        it 'succeeds' do
          expect(response.public_send(method)).to eq expected_value
        end
      end
    end

    context 'when response does not have the correct data' do
      where(:method, :expected_value) do
        :custom_score         | 0
        :global_score         | 0
        :risk_band            | 'Unavailable'
        :session_id           | 'Unavailable'
        :risk_category        | 'Unavailable'
        :global_telltale_list | 'Unavailable'
        :custom_telltale_list | 'Unavailable'
        :device_id            | nil
      end

      with_them do
        let(:json_response) { Gitlab::Json.parse("{}") }

        it 'succeeds' do
          expect(response.public_send(method)).to eq expected_value
        end
      end
    end
  end
end
