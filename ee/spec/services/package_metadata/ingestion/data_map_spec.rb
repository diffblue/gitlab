# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::DataMap, feature_category: :software_composition_analysis do
  context 'when storing packages' do
    let(:import_data) do
      [
        build(:pm_data_object, purl_type: 'npm', name: 'foo'),
        build(:pm_data_object, purl_type: 'npm', name: 'foo'),
        build(:pm_data_object, purl_type: 'maven', name: 'foo')
      ]
    end

    it 'correctly stores packages by purl_type and name' do
      map = described_class.new(import_data)
      expect(map.get_package_id('npm', 'foo')).to eq(nil)
      expect(map.get_package_id('maven', 'foo')).to eq(nil)
      map.set_package_id('npm', 'foo', 111)
      map.set_package_id('maven', 'foo', 222)
      expect(map.get_package_id('npm', 'foo')).to eq(111)
      expect(map.get_package_id('maven', 'foo')).to eq(222)
    end
  end

  context 'when storing package versions' do
    let(:import_data) do
      [
        build(:pm_data_object, purl_type: 'npm', name: 'foo', version: 'v1.0.0'),
        build(:pm_data_object, purl_type: 'npm', name: 'foo', version: 'v1.0.1'),
        build(:pm_data_object, purl_type: 'npm', name: 'bar', version: 'v1.0.0'),
        build(:pm_data_object, purl_type: 'maven', name: 'foo', version: 'v1.0.0')
      ]
    end

    subject(:map) { described_class.new(import_data) }

    before do
      map.set_package_id('npm', 'foo', 1)
      map.set_package_id('npm', 'bar', 2)
      map.set_package_id('maven', 'foo', 3)
    end

    it 'correctly stores package versions by package id and version' do
      expect(map.get_package_version_id('npm', 'foo', 'v1.0.0')).to eq(nil)
      expect(map.get_package_version_id('npm', 'foo', 'v1.0.1')).to eq(nil)
      expect(map.get_package_version_id('npm', 'bar', 'v1.0.0')).to eq(nil)
      expect(map.get_package_version_id('maven', 'foo', 'v1.0.0')).to eq(nil)
      map.set_package_version_id(1, 'v1.0.0', 11)
      map.set_package_version_id(1, 'v1.0.1', 12)
      map.set_package_version_id(2, 'v1.0.0', 13)
      map.set_package_version_id(3, 'v1.0.0', 14)
      expect(map.get_package_version_id('npm', 'foo', 'v1.0.0')).to eq(11)
      expect(map.get_package_version_id('npm', 'foo', 'v1.0.1')).to eq(12)
      expect(map.get_package_version_id('npm', 'bar', 'v1.0.0')).to eq(13)
      expect(map.get_package_version_id('maven', 'foo', 'v1.0.0')).to eq(14)
    end
  end

  context 'when storing licenses' do
    let(:import_data) do
      [
        build(:pm_data_object, license: 'MIT'),
        build(:pm_data_object, license: 'MIT'),
        build(:pm_data_object, license: 'Apache')
      ]
    end

    subject(:map) { described_class.new(import_data) }

    it 'stores the package version id' do
      expect(map.get_license_id('MIT')).to eq(nil)
      expect(map.get_license_id('Apache')).to eq(nil)
      map.set_license_id('MIT', 111)
      map.set_license_id('Apache', 222)
      expect(map.get_license_id('MIT')).to eq(111)
      expect(map.get_license_id('Apache')).to eq(222)
    end
  end
end
