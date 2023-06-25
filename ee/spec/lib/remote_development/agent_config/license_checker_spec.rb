# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::AgentConfig::LicenseChecker, feature_category: :remote_development do
  include ResultMatchers

  let(:value) { instance_double(Hash) }

  subject(:result) do
    described_class.check_license(value)
  end

  before do
    allow(License).to receive(:feature_available?).with(:remote_development) { licensed }
  end

  context 'when licensed' do
    let(:licensed) { true }

    it 'returns an ok Result containing the original value which was passed' do
      expect(result).to eq(Result.ok(value))
    end
  end

  context 'when unlicensed' do
    let(:licensed) { false }

    it 'returns an err Result containing an license check failed message with an empty context' do
      expect(result).to be_err_result(RemoteDevelopment::Messages::LicenseCheckFailed.new)
    end
  end
end
