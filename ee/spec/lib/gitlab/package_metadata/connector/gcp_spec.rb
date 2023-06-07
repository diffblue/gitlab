# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PackageMetadata::Connector::Gcp, feature_category: :software_composition_analysis do
  let(:connector) { described_class.new(bucket_name, version_format, purl_type) }
  let(:bucket_name) { 'gitlab-pm-bucket1' }
  let(:registry_id) { 'rubygem' }
  let(:purl_type) { 'gem' }
  let(:storage) { instance_double(Google::Cloud::Storage::Project, bucket: bucket) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, files: file_list) }
  let(:file_list) { instance_double(Google::Cloud::Storage::File::List, all: all_files) }
  let(:all_files) do
    [

      instance_double(Google::Cloud::Storage::File, name: "1675352601/00000000.#{file_suffix}"),
      instance_double(Google::Cloud::Storage::File, name: "1675352601/00000001.#{file_suffix}"),
      instance_double(Google::Cloud::Storage::File, name: "1675356202/00000000.#{file_suffix}"),
      instance_double(Google::Cloud::Storage::File, name: "1675356202/00000001.#{file_suffix}"),
      instance_double(Google::Cloud::Storage::File, name: "1675356202/00000002.#{file_suffix}"),
      instance_double(Google::Cloud::Storage::File, name: "1675359803/00000000.#{file_suffix}")
    ]
  end

  let(:file_suffix) { version_format == 'v2' ? 'ndjson' : 'csv' }

  before do
    allow(Google::Cloud::Storage).to receive(:anonymous).and_return(storage)
  end

  describe '.data_after(checkpoint)' do
    shared_examples_for 'it provides correct data' do
      let(:file_prefix) { "#{version_format}/#{bucket_name}" }
      let(:checkpoint) { PackageMetadata::Checkpoint.new(sequence: seq, chunk: chunk) }
      let(:expected_attributes) do
        expected_files.map do |file|
          seq, chunk = file.name.delete_prefix(file_prefix).split('/')
          have_attributes(sequence: seq.to_i, chunk: chunk.delete_suffix(file_suffix).to_i)
        end
      end

      subject(:data) { connector.data_after(checkpoint).to_a }

      before do
        allow(checkpoint).to receive(:blank?).and_return(seq.nil? || chunk.nil?)
      end

      it { expect(subject).to match(expected_attributes) }
    end

    %w[v1 v2].each do |version_format|
      context "when version format #{version_format}" do
        let(:version_format) { version_format }

        context 'when no seq/chunk passed' do
          let(:seq) { nil }
          let(:chunk) { nil }
          let(:expected_files) { all_files }

          it_behaves_like 'it provides correct data'
        end

        context 'when seq/chunk found' do
          context 'and data exists' do
            let(:seq) { 1675356202 }
            let(:chunk) { 1 }
            let(:expected_files) { all_files[4..] }

            it_behaves_like 'it provides correct data'
          end

          context 'and no data exists' do
            let(:seq) { 1675359803 }
            let(:chunk) { 0 }
            let(:expected_files) { [] }

            it_behaves_like 'it provides correct data'
          end
        end

        context 'when one of the parameters is not found' do
          context 'and it is seq' do
            let(:seq) { 1675356202 }
            let(:chunk) { 100 }
            let(:expected_files) { all_files }

            it_behaves_like 'it provides correct data'
          end

          context 'and it is chunk' do
            let(:seq) { 2222222 }
            let(:chunk) { 0 }
            let(:expected_files) { all_files }

            it_behaves_like 'it provides correct data'
          end

          context 'and both are not found' do
            let(:seq) { 123 }
            let(:chunk) { 456 }
            let(:expected_files) { all_files }

            it_behaves_like 'it provides correct data'
          end
        end
      end
    end
  end

  describe 'extracting CSV' do
    let(:file) { connector.data_after(PackageMetadata::Checkpoint.new(sequence: nil, chunk: nil)).first }
    let(:version_format) { 'v1' }

    before do
      allow(all_files.first).to receive(:download)
        .with(skip_decompress: true)
        .and_return(StringIO.new(string))
    end

    context 'with multiple lines' do
      let(:string) { "foo,v1,MIT\nbar,v100,Apache\n\nSkip me\nbaz,vx,some-other-license" }

      it 'extracts and converts every line to a DataObject' do
        expect { |b| file.each(&b) }.to yield_successive_args(
          have_attributes(name: 'foo', version: 'v1', license: 'MIT', purl_type: purl_type),
          have_attributes(name: 'bar', version: 'v100', license: 'Apache', purl_type: purl_type),
          have_attributes(name: 'baz', version: 'vx', license: 'some-other-license', purl_type: purl_type)
        )
      end
    end
  end

  describe 'extracting ndjson' do
    let(:version_format) { 'v2' }
    let(:file) { connector.data_after(PackageMetadata::Checkpoint.new(sequence: nil, chunk: nil)).first }

    before do
      allow(all_files.first).to receive(:download)
        .with(skip_decompress: true)
        .and_return(StringIO.new(string))
    end

    context 'with multiple lines' do
      let(:string) do
        File.open(Rails.root.join('ee/spec/fixtures/package_metadata/compressed_package_licenses_for_maven.ndjson'))
          .read
      end

      it 'extracts and converts every line to a DataObject' do
        expect { |b| file.each(&b) }.to yield_successive_args(
          have_attributes(purl_type: purl_type, name: 'ai.benshi.android.sdk/core', default_licenses: ['Apache-2.0'],
            lowest_version: '0.1.0-alpha01', highest_version: '1.2.0-rc01', other_licenses: []),
          have_attributes(purl_type: purl_type, name: 'xpp3/xpp3',
            default_licenses: ['unknown', 'Apache-1.1', 'CC-PDDC'], lowest_version: '1.1.4c', highest_version: '1.1.4c',
            other_licenses: [{ 'licenses' => ['unknown'],
                               'versions' => ['1.1.2a', '1.1.2a_min', '1.1.3.3', '1.1.3.3_min', '1.1.3.4.O',
                                 '1.1.3.4-RC3', '1.1.3.4-RC8'] }]),
          have_attributes(purl_type: purl_type, name: 'xml-apis/xml-apis', default_licenses: ['unknown'],
            lowest_version: '2.0.0', highest_version: '2.0.2', other_licenses:
            [{ 'licenses' => ['Apache-2.0'], 'versions' => ['1.3.04', '1.0.b2', '1.3.03'] },
              { 'licenses' => ['Apache-2.0', 'SAX-PD', 'W3C-20150513'], 'versions' => ['1.4.01'] }]),
          have_attributes(purl_type: purl_type, name: 'uk.org.retep.tools.maven/script',
            default_licenses: ['0BSD', 'Apache-1.1', 'Apache-2.0', 'BSD-2-Clause', 'CC-PDDC'],
            lowest_version: '10.1', highest_version: '9.8-RC1', other_licenses: [])
        )
      end
    end
  end

  describe 'gcp bucket' do
    using RSpec::Parameterized::TableSyntax

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
      context 'when version_format v1' do
        let(:version_format) { 'v1' }

        it 'correctly queries the bucket' do
          expect(bucket).to receive(:files).with(prefix: "#{version_format}/#{registry_id}/")
          connector.data_after(PackageMetadata::Checkpoint.new(sequence: nil, chunk: nil))
        end
      end

      context 'when version_format v2' do
        let(:version_format) { 'v2' }

        it 'correctly queries the bucket' do
          expect(bucket).to receive(:files).with(prefix: "#{version_format}/#{registry_id}/")
          connector.data_after(PackageMetadata::Checkpoint.new(sequence: nil, chunk: nil))
        end
      end
    end
  end
end
