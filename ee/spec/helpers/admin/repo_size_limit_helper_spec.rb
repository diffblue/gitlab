# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RepoSizeLimitHelper do
  describe '#repo_size_limit_feature_available?' do
    subject { helper.repo_size_limit_feature_available? }

    context 'when repository_size_limit feature is available' do
      before do
        stub_licensed_features(repository_size_limit: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when repo_size_limit_feature_available is not available' do
      before do
        stub_licensed_features(repository_size_limit: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when usage ping is enabled' do
      before do
        stub_licensed_features(repository_size_limit: false)
        stub_application_setting(usage_ping_enabled: true)
      end

      context 'when usage_ping_features is enabled' do
        before do
          stub_application_setting(usage_ping_features_enabled: true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when usage_ping_features is disabled' do
        before do
          stub_application_setting(usage_ping_features_enabled: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when usage ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
        stub_licensed_features(repository_size_limit: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
