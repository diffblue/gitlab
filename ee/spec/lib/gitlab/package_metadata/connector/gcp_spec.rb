# frozen_string_literal: true

require 'fast_spec_helper'
require 'hashie'
require './ee/app/services/package_metadata/data_object'

RSpec.describe Gitlab::PackageMetadata::Connector::Gcp, feature_category: :license_compliance do
  let(:connector) { described_class.new(bucket_name, version_format, purl_type) }
  let(:bucket_name) { 'gitlab-pm-bucket1' }
  let(:version_format) { 'v1' }
  let(:purl_type) { 'rubygems' }
  let(:storage) { instance_double(Google::Cloud::Storage::Project, bucket: bucket) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, files: file_list) }
  let(:file_list) { instance_double(Google::Cloud::Storage::File::List, all: all_files) }
  let(:all_files) do
    [

      instance_double(Google::Cloud::Storage::File, name: '1675352601/00000000.csv'),
      instance_double(Google::Cloud::Storage::File, name: '1675352601/00000001.csv'),
      instance_double(Google::Cloud::Storage::File, name: '1675356202/00000000.csv'),
      instance_double(Google::Cloud::Storage::File, name: '1675356202/00000001.csv'),
      instance_double(Google::Cloud::Storage::File, name: '1675356202/00000002.csv'),
      instance_double(Google::Cloud::Storage::File, name: '1675359803/00000000.csv')
    ]
  end

  before do
    allow(Google::Cloud::Storage).to receive(:anonymous).and_return(storage)
  end

  describe '.data_after(checkpoint)' do
    shared_examples_for 'it provides correct data' do
      let(:file_prefix) { "#{version_format}/#{bucket_name}" }
      let(:checkpoint) { Hashie::Mash.new(sequence_id: seq, chunk_id: chunk) }
      let(:expected_attributes) do
        expected_files.map do |file|
          seq, chunk = file.name.delete_prefix(file_prefix).split('/')
          have_attributes(sequence: seq.to_i, chunk: chunk.delete_suffix('.csv').to_i)
        end
      end

      subject(:data) { connector.data_after(checkpoint).to_a }

      before do
        allow(checkpoint).to receive(:blank?).and_return(seq.nil? || chunk.nil?)
      end

      it { is_expected.to match(expected_attributes) }
    end

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

  describe 'extracting CSV' do
    let(:file) { connector.data_after(Hashie::Mash.new(sequence_id: nil, chunk_id: nil)).first }

    before do
      allow(all_files.first).to receive(:download)
        .with(skip_decompress: true)
        .and_return(StringIO.new("foo,v1,MIT\nbar,v100,Apache\n\nSkip me\nbaz,vx,some-other-license"))
    end

    it 'extracts CSV lines correctly' do
      expect { |b| file.each(&b) }.to yield_successive_args(
        have_attributes(name: 'foo', version: 'v1', license: 'MIT', purl_type: purl_type),
        have_attributes(name: 'bar', version: 'v100', license: 'Apache', purl_type: purl_type),
        have_attributes(name: 'baz', version: 'vx', license: 'some-other-license', purl_type: purl_type)
      )
    end
  end

  describe 'gcp bucket' do
    it 'correctly queries the bucket' do
      expect(bucket).to receive(:files).with(prefix: "#{version_format}/#{purl_type}/")
      connector.data_after(Hashie::Mash.new(sequence_id: nil, chunk_id: nil))
    end
  end
end
