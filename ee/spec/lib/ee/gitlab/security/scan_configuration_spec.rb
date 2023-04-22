# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::ScanConfiguration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }

  let(:scan) { described_class.new(project: project, type: type) }

  describe '#available?' do
    subject { scan.available? }

    context 'with a core scanner' do
      let(:type) { :sast }

      before do
        stub_licensed_features(sast: false)
      end

      it 'core scanners (SAST, Secret Detection) are always available' do
        is_expected.to be_truthy
      end
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

    context 'when configuration in UI is available' do
      before do
        stub_licensed_features(security_configuration_in_ui: true)
      end

      context 'with licensed scanner' do
        let(:path) { "/#{project.full_path}/-/security/configuration" }

        where(:type, :configuration_path) do
          :sast | lazy { "#{path}/sast" }
          :dast | lazy { "#{path}/dast" }
          :dast_profiles | lazy { "#{path}/profile_library" }
          :api_fuzzing | lazy { "#{path}/api_fuzzing" }
          :corpus_management | lazy { "#{path}/corpus_management" }
        end

        with_them do
          it { is_expected.to eq(configuration_path) }
        end
      end

      context 'with a scanner' do
        let(:type) { :corpus_management }
        let(:configuration_path) { "/#{project.full_path}/-/security/configuration/corpus_management" }

        it { is_expected.to eq(configuration_path) }
      end
    end

    context 'when configuration in UI is not available' do
      let(:type) { :sast }

      it { is_expected.to be_nil }
    end
  end

  describe '#meta_info_path' do
    subject { scan.meta_info_path }

    context 'when configuration in UI and security on demand is not available' do
      before do
        stub_licensed_features(security_on_demand_scans: false, security_configuration_in_ui: false)
      end

      context 'with a scanner with meta path' do
        let(:type) { :dast }

        it { is_expected.to be_nil }
      end
    end

    context 'when configuration in UI and security on demand is available' do
      before do
        stub_licensed_features(security_on_demand_scans: true, security_configuration_in_ui: true)
      end

      context 'with a scanner without meta path' do
        let(:type) { :other_scanner }

        it { is_expected.to be_nil }
      end

      context 'with a scanner with meta path' do
        let(:type) { :dast }
        let(:meta_info_path) { "/#{project.full_path}/-/on_demand_scans" }

        it { is_expected.to eq(meta_info_path) }
      end
    end

    context 'when configuration in UI is not available and security on demand is available' do
      before do
        stub_licensed_features(security_on_demand_scans: true, security_configuration_in_ui: false)
      end

      context 'with a scanner without meta path' do
        let(:type) { :sast }

        it { is_expected.to be_nil }
      end

      context 'with a scanner with meta path' do
        let(:type) { :dast }

        it { is_expected.to be_nil }
      end
    end

    context 'when configuration in UI is available and security on demand is not available' do
      before do
        stub_licensed_features(security_on_demand_scans: false, security_configuration_in_ui: true)
      end

      where(:type, :meta_info_path) do
        :sast | nil
        :dast | nil
      end

      with_them do
        it { is_expected.to eq(meta_info_path) }
      end
    end
  end

  describe '#can_enable_by_merge_request?' do
    subject { scan.can_enable_by_merge_request? }

    context 'with a scanner that can be enabled in merge request' do
      where(type: %i(sast sast_iac secret_detection dependency_scanning container_scanning))

      with_them do
        it { is_expected.to be_truthy }
      end
    end

    context 'with a scanner that can not be enabled in merge request' do
      let(:type) { :dast }

      it { is_expected.to be_falsey }
    end
  end
end
