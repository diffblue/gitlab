# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::PackageVersionLicense, feature_category: :license_compliance do
  describe 'enums' do
    it { is_expected.to define_enum_for(:purl_type).with_values(Enums::Sbom::PURL_TYPES) }
  end

  describe 'association' do
    it { is_expected.to belong_to(:package_version).required }
    it { is_expected.to belong_to(:license).required }
  end
end
