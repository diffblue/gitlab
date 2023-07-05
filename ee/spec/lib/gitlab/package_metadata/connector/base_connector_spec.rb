# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PackageMetadata::Connector::BaseConnector, feature_category: :software_composition_analysis do
  let(:sync_config) { build(:pm_sync_config, version_format: version_format) }
  let(:connector) { described_class.new(sync_config) }

  describe '.data_file_class' do
    subject(:data_file_class) { connector.send(:data_file_class) }

    context 'when version_format v2' do
      let(:version_format) { 'v2' }

      it { is_expected.to be(::Gitlab::PackageMetadata::Connector::NdjsonDataFile) }
    end

    context 'when version_format v1' do
      let(:version_format) { 'v1' }

      it { is_expected.to be(::Gitlab::PackageMetadata::Connector::CsvDataFile) }
    end
  end
end
