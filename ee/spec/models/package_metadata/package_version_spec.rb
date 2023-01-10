# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::PackageVersion, feature_category: :license_compliance do
  describe 'enums' do
    it { is_expected.to define_enum_for(:purl_type).with_values(Enums::Sbom::PURL_TYPES) }
  end

  describe 'association' do
    it { is_expected.to belong_to(:package).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_length_of(:version).is_at_most(255) }
  end
end
