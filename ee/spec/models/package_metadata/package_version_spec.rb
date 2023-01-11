# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::PackageVersion do
  describe 'association' do
    it { is_expected.to belong_to(:package).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_length_of(:version).is_at_most(255) }
  end
end
