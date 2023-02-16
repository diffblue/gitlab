# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::License, type: :model, feature_category: :license_compliance do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:spdx_identifier) }
    it { is_expected.to validate_length_of(:spdx_identifier).is_at_most(50) }
  end
end
