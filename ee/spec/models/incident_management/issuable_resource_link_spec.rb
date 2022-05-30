# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableResourceLink, type: :model do
  let_it_be(:issuable_resource_link) { create(:issuable_resource_link) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:link) }
    it { is_expected.to validate_length_of(:link).is_at_most(2200) }
    it { is_expected.to validate_length_of(:link_text).is_at_most(255) }
  end

  describe 'enums' do
    let(:link_type_values) do
      { general: 0, zoom: 1, slack: 2 }
    end

    it { is_expected.to define_enum_for(:link_type).with_values(link_type_values) }
  end
end
