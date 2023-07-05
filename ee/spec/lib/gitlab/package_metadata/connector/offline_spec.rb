# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::PackageMetadata::Connector::Offline, feature_category: :software_composition_analysis do
  using RSpec::Parameterized::TableSyntax

  shared_examples_for 'it provides correct data' do
    let(:checkpoint) do
      build(:pm_checkpoint, sequence: seq, chunk: chunk, version_format: sync_config.version_format,
        purl_type: sync_config.purl_type)
    end

    let(:paths) do
      [
        "0/0.#{file_suffix}",
        "1/0.#{file_suffix}",
        "2/0.#{file_suffix}",
        "3/0.#{file_suffix}"
      ]
    end

    subject(:data) { connector.data_after(checkpoint).to_a }

    context "when no checkpoint is given" do
      let(:seq) { nil }
      let(:chunk) { nil }

      it {
        is_expected.to match([
          have_attributes(sequence: 0, chunk: 0), have_attributes(sequence: 1, chunk: 0),
          have_attributes(sequence: 2, chunk: 0), have_attributes(sequence: 3, chunk: 0)
        ])
      }
    end

    context "when a checkpoint is given" do
      context "when sequence exists and chunk do not" do
        let(:seq) { 2 }
        let(:chunk) { 1 }

        it {
          is_expected.to match([
            have_attributes(sequence: 0, chunk: 0), have_attributes(sequence: 1, chunk: 0),
            have_attributes(sequence: 2, chunk: 0), have_attributes(sequence: 3, chunk: 0)
          ])
        }
      end

      context "when sequence and chunk do not exist" do
        let(:seq) { 4 }
        let(:chunk) { 0 }

        it {
          is_expected.to match([
            have_attributes(sequence: 0, chunk: 0), have_attributes(sequence: 1, chunk: 0),
            have_attributes(sequence: 2, chunk: 0), have_attributes(sequence: 3, chunk: 0)
          ])
        }
      end

      context "when sequence and chunk both exist" do
        let(:seq) { 1 }
        let(:chunk) { 0 }

        it {
          is_expected.to match([
            have_attributes(sequence: 2, chunk: 0), have_attributes(sequence: 3, chunk: 0)
          ])
        }
      end
    end
  end

  # The license db does not use a directory structure
  # that maps 1:1 with the purl types. Therefore,
  # we test that we correctly convert between purl type
  # and registry id used by the license db structure.
  where(:purl_type, :registry_id) do
    :composer | "packagist"
    :conan | "conan"
    :gem | "rubygem"
    :golang | "go"
    :maven | "maven"
    :npm | "npm"
    :nuget | "nuget"
    :pypi | "pypi"
    :apk | "apk"
    :rpm | "rpm"
    :deb | "deb"
    :cbl_mariner | "cbl-mariner"
  end

  let(:sync_config) do
    build(:pm_sync_config, :for_offline_license_storage, version_format: version_format, purl_type: purl_type)
  end

  let(:file_prefix) { File.join(sync_config.base_uri, version_format, registry_id) }
  let(:connector) { described_class.new(sync_config) }

  subject(:data_files) { connector.data_after(checkpoint).to_a }

  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with("*/*.#{file_suffix}", base: file_prefix).and_return(paths)
    allow(File).to receive(:open).and_call_original
    paths.each do |path|
      fullpath = File.absolute_path(path, file_prefix)
      allow(File).to receive(:open).with(fullpath, 'r').and_return(StringIO.new)
    end
  end

  with_them do
    context 'when version_format v1' do
      let(:version_format) { 'v1' }
      let(:file_suffix) { 'csv' }

      it_behaves_like 'it provides correct data'
    end

    context 'when version_format v2' do
      let(:version_format) { 'v2' }
      let(:file_suffix) { 'ndjson' }

      it_behaves_like 'it provides correct data'
    end
  end
end
