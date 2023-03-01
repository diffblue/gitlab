# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SetFeatureFlagService, feature_category: :feature_flags do
  let(:service) { described_class.new(feature_flag_name: feature_name, params: params) }

  describe '#execute' do
    subject { service.execute }

    context 'when enabling the feature flag that is a licensed feature' do
      let(:params) { { value: 'true' } }
      let(:feature_name) { GitlabSubscriptions::Features::ALL_ULTIMATE_FEATURES.sample }

      it 'returns an error' do
        expect(Feature).not_to receive(:enable)
        expect(subject).to be_error
        expect(subject.reason).to eq(:invalid_feature_flag)
      end

      context 'when force: true' do
        let(:params) { { value: 'true', force: true } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name)
          expect(subject).to be_success
        end
      end
    end
  end
end
