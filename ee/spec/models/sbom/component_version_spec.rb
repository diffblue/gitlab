# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::ComponentVersion, type: :model, feature_category: :dependency_management do
  describe 'associations' do
    it { is_expected.to belong_to(:component).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_length_of(:version).is_at_most(255) }
  end
end
