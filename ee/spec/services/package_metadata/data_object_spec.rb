# frozen_string_literal: true

require 'fast_spec_helper'
require './ee/app/services/package_metadata/data_object'

RSpec.describe PackageMetadata::DataObject, feature_category: :license_compliance do
  describe 'equality' do
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
