# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Checkpoint, type: :model, feature_category: :software_composition_analysis do
  let(:purl_types) do
    {
      composer: 1,
      conan: 2,
      gem: 3,
      golang: 4,
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      cbl_mariner: 12
    }
  end

  let(:data_types) do
    {
      advisories: 1,
      licenses: 2
    }
  end

  let(:version_formats) do
    {
      v1: 1,
      v2: 2
    }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:purl_type).with_values(purl_types) }
    it { is_expected.to define_enum_for(:data_type).with_values(data_types) }
    it { is_expected.to define_enum_for(:version_format).with_values(version_formats) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:purl_type) }
    it { is_expected.to validate_presence_of(:data_type) }
    it { is_expected.to validate_presence_of(:version_format) }

    it { is_expected.to validate_presence_of(:sequence) }
    it { is_expected.to validate_numericality_of(:sequence).only_integer }

    it { is_expected.to validate_presence_of(:chunk) }
    it { is_expected.to validate_numericality_of(:chunk).only_integer }

    it do
      create(:pm_checkpoint)

      is_expected.to validate_uniqueness_of(
        :purl_type
      ).scoped_to([:data_type, :version_format]).ignoring_case_sensitivity
    end
  end

  describe '.with_purl_type' do
    let(:checkpoints) { create_list(:pm_checkpoint, 12) }

    it 'returns the checkpoint for the given parameters' do
      checkpoints.each do |checkpoint|
        actual = described_class.with_purl_type(checkpoint.purl_type)
        expect(actual).to eq(checkpoint)
      end
    end
  end
end
