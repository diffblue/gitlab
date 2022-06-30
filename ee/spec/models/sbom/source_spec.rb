# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Source, type: :model do
  let(:source_types) { { dependency_file: 0, container_image: 1 } }

  describe 'enums' do
    it { is_expected.to define_enum_for(:source_type).with_values(source_types) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:fingerprint) }
  end

  describe 'source validation' do
    subject { build(:sbom_source, source: source_attributes) }

    context 'when source is valid' do
      let(:source_attributes) do
        {
          dependency_file: 'package-lock.json',
          package_manager_name: 'npm',
          language: 'JavaScript'
        }
      end

      it { is_expected.to be_valid }
    end

    context 'when optional attributes are missing' do
      let(:source_attributes) do
        {
          dependency_file: 'package-lock.json'
        }
      end

      it { is_expected.to be_valid }
    end

    context 'when dependency_file is missing' do
      let(:source_attributes) do
        {
          package_manager_name: 'npm',
          language: 'JavaScript'
        }
      end

      it { is_expected.to be_invalid }
    end

    context 'when attributes have wrong type' do
      let(:source_attributes) do
        {
          dependency_file: 1,
          package_manager_name: 2,
          language: 3
        }
      end

      it { is_expected.to be_invalid }
    end
  end
end
