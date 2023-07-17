# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::PackageMetadata::Connector::BaseDataFile, feature_category: :software_composition_analysis do
  describe '.each' do
    let(:sequence) { 1684174390 }
    let(:chunk) { 0 }
    let(:purl_type) { :npm }

    subject { data_file.to_a }

    context 'when container class is the base class DataFile' do
      let(:io) { StringIO.new("rails,v7.2,MIT\nactiverecord,v6.1,Apache") }
      let(:data_file) { described_class.new(io, sequence, chunk) }

      it 'throws a not implemented error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when container class is CsvDataFile' do
      let(:io) { StringIO.new("rails,v7.2,MIT\nactiverecord,v6.1,Apache") }

      let(:data_file) do
        ::Gitlab::PackageMetadata::Connector::CsvDataFile.new(io, sequence, chunk)
      end

      context 'and io passed is of valid CSV' do
        let(:io) { StringIO.new("rails,v7.2,MIT\nactiverecord,v6.1,Apache") }

        it { is_expected.to match_array([['rails', 'v7.2', 'MIT'], ['activerecord', 'v6.1', 'Apache']]) }

        context 'and is escaped unicode' do
          let(:io) { StringIO.new((+"räils,v7.2,MIT\näctiverecord,v6.1,Äpäche").force_encoding('ASCII-8BIT')) }

          it { is_expected.to match_array([['räils', 'v7.2', 'MIT'], ['äctiverecord', 'v6.1', 'Äpäche']]) }
        end
      end

      context 'and io passed is invalid' do
        let(:io) { StringIO.new('x,\"') }

        it { is_expected.to be_empty }

        it 'warns about the error' do
          expect(Gitlab::AppJsonLogger).to receive(:warn)
            .with(class: 'Gitlab::PackageMetadata::Connector::CsvDataFile',
              message: "csv parsing error on '#{io.string}'", error: 'Illegal quoting in line 1.')
          data_file.to_a
        end
      end
    end

    context 'when container class is NdjsonDataFile' do
      subject { data_file.to_a }

      let(:data_file) do
        ::Gitlab::PackageMetadata::Connector::NdjsonDataFile.new(io, sequence, chunk)
      end

      context 'and io passed is of valid NDJSON' do
        let(:io) do
          StringIO.new(
            "{ \"name\": \"rails\", \"licenses\": [[\"MIT\"],null,\"v7.2\",[]]}\n" \
            '{ "name": "activerecord", "licenses": [["Apache"],"v4.0.0","v6.1.1",[]]}'
          )
        end

        it {
          is_expected.to match_array([
            { 'name' => 'rails', 'licenses' => [["MIT"], nil, "v7.2", []] },
            { 'name' => 'activerecord', 'licenses' => [["Apache"], "v4.0.0", "v6.1.1", []] }
          ])
        }

        context 'and is escaped unicode' do
          let(:io) do
            StringIO.new(
              (+"{ \"name\": \"räils\", \"licenses\": [[\"MIT\"],null,\"v7.2\",[]]}\n" \
                '{ "name": "äctiverecord", "licenses": [["Äpäche"],"v4.0.0","v6.1.1",[]]}')
              .force_encoding('ASCII-8BIT')
            )
          end

          it {
            is_expected.to match_array([
              { 'name' => 'räils', 'licenses' => [["MIT"], nil, "v7.2", []] },
              { 'name' => 'äctiverecord', 'licenses' => [["Äpäche"], "v4.0.0", "v6.1.1", []] }
            ])
          }
        end
      end

      context 'and io passed is invalid' do
        let(:io) { StringIO.new('{"name": }') }

        it { is_expected.to be_empty }

        it 'warns about the error' do
          expect(Gitlab::AppJsonLogger).to receive(:warn)
            .with(class: 'Gitlab::PackageMetadata::Connector::NdjsonDataFile',
              message: "json parsing error on '#{io.string}'",
              error: start_with('expected hash value, not a hash close (after name) at line 1, column 10'))
          data_file.to_a
        end
      end
    end
  end

  describe '.checkpoint?' do
    let(:sequence) { 1684174390 }
    let(:chunk) { 0 }
    let(:data_file) { described_class.new(StringIO.new, sequence, chunk) }

    subject(:checkpoint?) { data_file.checkpoint?(checkpoint) }

    context 'when checkpoint has same sequence and chunk' do
      let(:checkpoint) { build(:pm_checkpoint, sequence: sequence, chunk: chunk) }

      it { is_expected.to be(true) }
    end

    context 'when checkpoint has different sequence' do
      let(:checkpoint) { build(:pm_checkpoint, sequence: sequence + 1, chunk: chunk) }

      it { is_expected.to be(false) }
    end

    context 'when checkpoint has different chunk' do
      let(:checkpoint) { build(:pm_checkpoint, sequence: sequence, chunk: chunk + 1) }

      it { is_expected.to be(false) }
    end

    context 'when checkpoint has different sequence and chunk' do
      let(:checkpoint) { build(:pm_checkpoint, sequence: sequence + 1, chunk: chunk + 1) }

      it { is_expected.to be(false) }
    end
  end

  describe '#to_s' do
    context 'when ndjson' do
      subject { ::Gitlab::PackageMetadata::Connector::NdjsonDataFile.new(StringIO.new, 1684175500, 99999).to_s }

      it { is_expected.to eq("1684175500/99999.ndjson") }
    end

    context 'when csv' do
      subject { ::Gitlab::PackageMetadata::Connector::CsvDataFile.new(StringIO.new, 1684175500, 99999).to_s }

      it { is_expected.to eq("1684175500/99999.csv") }
    end
  end
end
