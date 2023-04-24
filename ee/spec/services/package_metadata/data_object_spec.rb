# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::DataObject, feature_category: :software_composition_analysis do
  describe '.from_csv' do
    let(:purl_type) { 'npm' }

    subject(:object) { described_class.from_csv(text, purl_type) }

    context 'when text is well-formed' do
      let(:text) { 'foo,v1.0.0,MIT' }

      it { is_expected.to eq(described_class.new('foo', 'v1.0.0', 'MIT', purl_type)) }
    end

    context 'when text is escaped unicode' do
      let(:text) { (+'fóó,vérsion-1,Àpache').force_encoding('ASCII-8BIT') }

      it { is_expected.to eq(described_class.new('fóó', 'vérsion-1', 'Àpache', purl_type)) }
    end

    context 'when text is not well-formed' do
      context 'if it does not have 3 fields' do
        let(:text) { 'foo,v1.0.0' }

        it { is_expected.to eq(nil) }
      end

      context 'if an entry is blank' do
        ['foo,v1,""', '"",v1,MIT', 'foo,"",MIT'].each do |t|
          context "with #{t}" do
            let(:text) { t }

            it { is_expected.to eq(nil) }
          end
        end
      end

      context 'if an entry is missing' do
        ['foo,v1,', ',v1,MIT', 'foo,,MIT'].each do |t|
          context "with #{t}" do
            let(:text) { t }

            it { is_expected.to eq(nil) }
          end
        end
      end

      context 'and field is longer than expected' do
        let(:name) { 'package' * 256 }
        let(:version) { 'version' * 256 }
        let(:license) { 'license' * 51 }

        let(:text) { "#{name},#{version},#{license}" }

        context 'and it is package name' do
          subject { object.name.length }

          it { is_expected.to eq(255) }
        end

        context 'and it is package version' do
          subject { object.version.length }

          it { is_expected.to eq(255) }
        end

        context 'and it is license' do
          subject { object.license.length }

          it { is_expected.to eq(50) }
        end
      end

      context 'and it is invalid csv' do
        let(:text) { 'sndfileio,\"0.6\n' }

        it 'catches the error' do
          expect { object }.not_to raise_error
        end

        it 'logs the error' do
          expect(Gitlab::AppJsonLogger).to receive(:error).and_call_original
          object
        end

        it 'returns nil' do
          expect(object).to eq(nil)
        end
      end
    end
  end

  describe '==' do
    let(:obj) { described_class.new('foo', 'v1', 'mit', 'rubygems') }
    let(:other) { described_class.new('foo', 'v1', 'mit', 'rubygems') }

    subject(:equality) { obj == other }

    context 'when all attributes are equal' do
      let(:obj) { described_class.new('foo', 'v1', 'mit', 'rubygems') }
      let(:other) { described_class.new('foo', 'v1', 'mit', 'rubygems') }

      it { is_expected.to eq(true) }
    end

    context 'when an attribute is not equal' do
      let(:name) { 'foo' }
      let(:version) { 'v1' }
      let(:license) { 'mit' }
      let(:purl_type) { 'rubygems' }
      let(:obj) { described_class.new(name, version, license, purl_type) }

      context 'and it is name' do
        let(:other) { described_class.new("#{name}foo", version, license, purl_type) }

        context 'and the purl_type is not pypi' do
          it { is_expected.to eq(false) }
        end

        context 'and the purl_type is pypi' do
          let(:purl_type) { 'pypi' }

          it { is_expected.to eq(false) }
        end
      end

      context 'and it is version' do
        let(:other) { described_class.new(name, "#{version}foo", license, purl_type) }

        it { is_expected.to eq(false) }
      end

      context 'and it is license' do
        let(:other) { described_class.new(name, version, "#{license}foo", purl_type) }

        it { is_expected.to eq(false) }
      end

      context 'and it is purl_type' do
        let(:other) { described_class.new(name, version, license, 'foo') }

        it { is_expected.to eq(false) }
      end
    end
  end
end
