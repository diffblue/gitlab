# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PackageMetadata::Connector::Gcp, feature_category: :software_composition_analysis do
  let(:sync_config) { build(:pm_sync_config, version_format: version_format, purl_type: purl_type) }
  let(:connector) { described_class.new(sync_config) }
  let(:storage) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, files: file_list) }
  let(:file_list) { instance_double(Google::Cloud::Storage::File::List, all: all_files) }
  let(:all_files) { file_names.map { |name| instance_double(Google::Cloud::Storage::File, name: name) } }
  let(:file_names) do
    [
      "#{version_format}/#{registry_id}/1675352601/00000000.#{file_suffix}",
      "#{version_format}/#{registry_id}/1675352601/00000001.#{file_suffix}",
      "#{version_format}/#{registry_id}/1675356202/00000000.#{file_suffix}",
      "#{version_format}/#{registry_id}/1675356202/00000001.#{file_suffix}",
      "#{version_format}/#{registry_id}/1675356202/00000002.#{file_suffix}",
      "#{version_format}/#{registry_id}/1675359803/00000000.#{file_suffix}"
    ]
  end

  let(:file_suffix) { sync_config.version_format == 'v1' ? 'csv' : 'ndjson' }

  before do
    allow(Google::Cloud::Storage).to receive(:anonymous).and_return(storage)
    allow(storage).to receive(:bucket).with(sync_config.base_uri, skip_lookup: true).and_return(bucket)
  end

  describe '.data_after(checkpoint)' do
    using RSpec::Parameterized::TableSyntax

    let(:checkpoint) { nil }

    subject(:data) { connector.data_after(checkpoint).to_a }

    shared_examples_for 'a gcp bucket enumerator' do
      let(:checkpoint) do
        build(:pm_checkpoint, sequence: seq, chunk: chunk, version_format: sync_config.version_format,
          purl_type: sync_config.purl_type)
      end

      context 'when no seq/chunk passed' do
        let(:seq) { nil }
        let(:chunk) { nil }
        let(:expected_files) { all_files }

        it {
          is_expected.to match([
            have_attributes(sequence: 1675352601, chunk: 0),
            have_attributes(sequence: 1675352601, chunk: 1),
            have_attributes(sequence: 1675356202, chunk: 0),
            have_attributes(sequence: 1675356202, chunk: 1),
            have_attributes(sequence: 1675356202, chunk: 2),
            have_attributes(sequence: 1675359803, chunk: 0)
          ])
        }
      end

      context 'when seq/chunk found' do
        context 'and data exists' do
          let(:seq) { 1675356202 }
          let(:chunk) { 1 }
          let(:expected_files) { all_files[4..] }

          it {
            is_expected.to match([
              have_attributes(sequence: 1675356202, chunk: 2),
              have_attributes(sequence: 1675359803, chunk: 0)
            ])
          }
        end

        context 'and no data exists' do
          let(:seq) { 1675359803 }
          let(:chunk) { 0 }
          let(:expected_files) { [] }

          it { is_expected.to match([]) }
        end
      end

      context 'when one of the parameters is not found' do
        context 'and it is seq' do
          let(:seq) { 1675356202 }
          let(:chunk) { 100 }
          let(:expected_files) { all_files }

          it {
            is_expected.to match([
              have_attributes(sequence: 1675352601, chunk: 0),
              have_attributes(sequence: 1675352601, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 0),
              have_attributes(sequence: 1675356202, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 2),
              have_attributes(sequence: 1675359803, chunk: 0)
            ])
          }
        end

        context 'and it is chunk' do
          let(:seq) { 2222222 }
          let(:chunk) { 0 }
          let(:expected_files) { all_files }

          it {
            is_expected.to match([
              have_attributes(sequence: 1675352601, chunk: 0),
              have_attributes(sequence: 1675352601, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 0),
              have_attributes(sequence: 1675356202, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 2),
              have_attributes(sequence: 1675359803, chunk: 0)
            ])
          }
        end

        context 'and both are not found' do
          let(:seq) { 123 }
          let(:chunk) { 456 }
          let(:expected_files) { all_files }

          it {
            is_expected.to match([
              have_attributes(sequence: 1675352601, chunk: 0),
              have_attributes(sequence: 1675352601, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 0),
              have_attributes(sequence: 1675356202, chunk: 1),
              have_attributes(sequence: 1675356202, chunk: 2),
              have_attributes(sequence: 1675359803, chunk: 0)
            ])
          }
        end
      end
    end

    shared_examples_for 'a lazy file downloader' do
      let(:all_files) { [gcp_file] }
      let(:gcp_file) do
        instance_double(Google::Cloud::Storage::File, name: "/1678352601/00000000.#{file_suffix}",
          download: io)
      end

      let(:io) { version_format == 'v1' ? StringIO.new("1\n2\n3") : StringIO.new("[\"1\"]\n[\"2\"]\n[\"3\"]") }

      it 'does not download the gcp file when gcp file list retrieved' do
        expect(gcp_file).not_to receive(:download)
        connector.data_after(checkpoint)
      end

      it 'downloads the gcp file only when iterating over data_file' do
        expect(gcp_file).to receive(:download)
        connector.data_after(checkpoint).each do |data_file|
          expect(data_file.to_a).to match_array([['1'], ['2'], ['3']])
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

    with_them do
      context 'when version format v1' do
        let(:version_format) { 'v1' }

        it_behaves_like 'a gcp bucket enumerator'

        it_behaves_like 'a lazy file downloader'

        it { is_expected.to all(be_a(Gitlab::PackageMetadata::Connector::CsvDataFile)) }
      end

      context 'when version format v2' do
        let(:version_format) { 'v2' }

        it_behaves_like 'a gcp bucket enumerator'

        it_behaves_like 'a lazy file downloader'

        it { is_expected.to all(be_a(Gitlab::PackageMetadata::Connector::NdjsonDataFile)) }
      end
    end
  end
end
