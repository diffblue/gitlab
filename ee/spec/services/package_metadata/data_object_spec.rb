# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::DataObject, feature_category: :software_composition_analysis do
  describe '.create' do
    let(:purl_type) { 'npm' }
    let(:sync_config) { SyncConfiguration.new(:gcp, 'bucket', 'v1', purl_type) }

    subject(:object) { described_class.create(arr, purl_type) }

    context 'when arr is well-formed' do
      let(:arr) { ['foo', 'v1.0.0', 'MIT'] }

      it { is_expected.to eq(described_class.new('foo', 'v1.0.0', 'MIT', purl_type)) }
    end

    context 'when arr is not well-formed' do
      context 'with less than 3 fields' do
        let(:arr) { ['foo', 'v1.0.0'] }

        it { is_expected.to eq(nil) }

        it 'warns about the error' do
          expect(Gitlab::AppJsonLogger).to receive(:warn).with(class: described_class.name,
            message: "Invalid data passed to .create: #{arr}")
          described_class.create(arr, purl_type)
        end
      end

      context 'and field is longer than expected' do
        let(:name) { 'package' * 256 }
        let(:version) { 'version' * 256 }
        let(:license) { 'license' * 51 }

        let(:arr) { [name, version, license] }

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
