# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::PackageVersionLicense do
  describe 'association' do
    it { is_expected.to belong_to(:package_version).required }
    it { is_expected.to belong_to(:license).required }
  end
end
