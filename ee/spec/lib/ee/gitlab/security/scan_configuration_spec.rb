# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::ScanConfiguration do
  let_it_be(:project) { create(:project, :repository) }

  let(:scan) { described_class.new(project: project, type: type, configured: configured) }

  describe '#available?' do
    subject { scan.available? }

    let(:configured) { true }

    context 'with a core scanner' do
      let(:type) { :sast }

      before do
        stub_licensed_features(sast: false)
      end

      it { is_expected.to be_truthy }
    end

    context 'with licensed scanner that is available' do
      let(:type) { :api_fuzzing }

      before do
        stub_licensed_features(api_fuzzing: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'with licensed scanner that is not available' do
      let(:type) { :api_fuzzing }

      before do
        stub_licensed_features(api_fuzzing: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'with custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_falsey }
    end
  end

  describe '#configuration_path' do
    subject { scan.configuration_path }

    let(:configured) { true }

    context 'with licensed scanner' do
      let(:type) { :dast }
      let(:configuration_path) { "/#{project.namespace.path}/#{project.name}/-/security/configuration/dast" }

      before do
        stub_licensed_features(dast: true)
      end

      it { is_expected.to eq(configuration_path) }
    end

    context 'with a scanner under feature flag' do
      let(:type) { :corpus_management }
      let(:configuration_path) { "/#{project.namespace.path}/#{project.name}/-/security/configuration/corpus_management" }

      it { is_expected.to eq(configuration_path) }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(corpus_management: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
