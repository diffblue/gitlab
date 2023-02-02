# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Source, type: :model, feature_category: :dependency_management do
  let(:source_types) { { dependency_scanning: 0, container_scanning: 1 } }

  describe 'enums' do
    it { is_expected.to define_enum_for(:source_type).with_values(source_types) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:source) }
  end

  describe 'source validation' do
    subject { build(:sbom_source, source: source_attributes) }

    context 'when source is valid' do
      let(:source_attributes) do
        {
          'category' => 'development',
          'input_file' => { 'path' => 'package-lock.json' },
          'source_file' => { 'path' => 'package.json' },
          'package_manager' => { 'name' => 'npm' },
          'language' => { 'name' => 'JavaScript' }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'when optional attributes are missing' do
      let(:source_attributes) do
        {
          'input_file' => { 'path' => 'package-lock.json' }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'when input_file is missing' do
      let(:source_attributes) do
        {
          'package_manager' => { 'name' => 'npm' },
          'language' => { 'name' => 'JavaScript' }
        }
      end

      it { is_expected.to be_invalid }
    end

    context 'when attributes have wrong type' do
      let(:source_attributes) do
        {
          'category' => 'development',
          'input_file' => { 'path' => 1 },
          'source_file' => { 'path' => 'package.json' },
          'package_manager' => { 'name' => 2 },
          'language' => { 'name' => 3 }
        }
      end

      it { is_expected.to be_invalid }
    end
  end

  describe 'readers' do
    let(:source_attributes) do
      {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    end

    let(:source) { build(:sbom_source, source: source_attributes) }

    describe '#packager' do
      subject { source.packager }

      it { is_expected.to eq('npm') }
    end

    describe '#input_file_path' do
      subject { source.input_file_path }

      it { is_expected.to eq('package-lock.json') }
    end
  end
end
