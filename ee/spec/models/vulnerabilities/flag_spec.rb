# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Flag do
  describe 'associations' do
    it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').with_foreign_key('vulnerability_occurrence_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:origin).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:flag_type) }
    it { is_expected.to define_enum_for(:flag_type).with_values(false_positive: 0) }
  end
end
