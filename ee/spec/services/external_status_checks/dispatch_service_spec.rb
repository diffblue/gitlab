# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::DispatchService, feature_category: :projects do
  let_it_be(:rule) { build_stubbed(:external_status_check, external_url: 'https://test.example.com/callback') }

  subject { described_class.new(rule, {}).execute }

  describe '#execute' do
    context 'service responds with success' do
      before do
        stub_success
      end

      it 'is successful' do
        expect(subject.success?).to be true
      end

      it 'passes back the http status code' do
        expect(subject.http_status).to eq(200)
      end
    end

    context 'service responds with error' do
      before do
        stub_failure
      end

      it 'is unsuccessful' do
        expect(subject.success?).to be false
      end

      it 'passes back the http status code' do
        expect(subject.http_status).to eq(500)
      end
    end
  end

  private

  def stub_success
    stub_request(:post, 'https://test.example.com/callback')
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_failure
    stub_request(:post, 'https://test.example.com/callback')
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 500, body: "", headers: {})
  end
end
