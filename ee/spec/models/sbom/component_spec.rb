# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Component, type: :model do
  let(:component_types) { { library: 0 } }

  describe 'enums' do
    it { is_expected.to define_enum_for(:component_type).with_values(component_types) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:component_type) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end
end
