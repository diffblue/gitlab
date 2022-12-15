# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Sbom::VulnerableComponentVersion, type: :model, feature_category: :dependency_management do
  subject(:version) { build(:vulnerable_component_version) }

  describe 'associations' do
    it { is_expected.to belong_to(:advisory).required }
    it { is_expected.to belong_to(:component_version).required }
  end
end
