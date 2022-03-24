# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnerReleases do
  subject { described_class.instance }

  describe '#releases' do
    before do
      subject.reset!

      stub_application_setting(public_runner_releases_url: 'the release API URL')
      allow(Gitlab::HTTP).to receive(:try_get).with('the release API URL').once { mock_http_response(response) }
    end

    def releases
      subject.releases
    end

    shared_examples 'requests that follow cache status' do |validity_period|
      context "almost #{validity_period.inspect} later" do
        let(:followup_request_interval) { validity_period - 0.001.seconds }

        it 'returns cached releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).not_to receive(:try_get)

            expect(releases).to eq(expected_result)
          end
        end
      end

      context "after #{validity_period.inspect}" do
        let(:followup_request_interval) { validity_period + 1.second }
        let(:followup_response) { (response || []) + [{ 'name' => 'v14.9.2' }] }

        it 'checks new releases' do
          releases

          travel followup_request_interval do
            expect(Gitlab::HTTP).to receive(:try_get).with('the release API URL').once { mock_http_response(followup_response) }

            expect(releases).to eq((expected_result || []) + [Gitlab::VersionInfo.new(14, 9, 2)])
          end
        end
      end
    end

    context 'when response is nil' do
      let(:response) { nil }
      let(:expected_result) { nil }

      it 'returns nil' do
        expect(releases).to be_nil
      end

      it_behaves_like 'requests that follow cache status', 5.seconds
    end

    context 'when response is not nil' do
      let(:response) { [{ 'name' => 'v14.9.1' }, { 'name' => 'v14.9.0' }] }
      let(:expected_result) { [Gitlab::VersionInfo.new(14, 9, 0), Gitlab::VersionInfo.new(14, 9, 1)] }

      it 'returns parsed and sorted Gitlab::VersionInfo objects' do
        expect(releases).to eq(expected_result)
      end

      it_behaves_like 'requests that follow cache status', 1.day
    end

    def mock_http_response(response)
      http_response = instance_double(HTTParty::Response)

      allow(http_response).to receive(:success?).and_return(response.present?)
      allow(http_response).to receive(:parsed_response).and_return(response)

      http_response
    end
  end
end
