# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Package, type: :model, feature_category: :license_compliance do
  describe 'enums' do
    it { is_expected.to define_enum_for(:purl_type).with_values(Enums::Sbom::PURL_TYPES) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:purl_type) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
