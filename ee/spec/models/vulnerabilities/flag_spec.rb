# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Flag, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:finding).class_name('Vulnerabilities::Finding').with_foreign_key('vulnerability_occurrence_id').required }
  end

  describe 'validations' do
    subject { build(:vulnerabilities_flag) }

    it { is_expected.to validate_length_of(:origin).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:flag_type) }
    it { is_expected.to validate_uniqueness_of(:flag_type).scoped_to(:vulnerability_occurrence_id, :origin).ignoring_case_sensitivity }
    it { is_expected.to define_enum_for(:flag_type).with_values(false_positive: 0) }
  end

  describe '#initialize' do
    it 'creates a valid flag with flag_type attribute' do
      flag = described_class.new(flag_type: Vulnerabilities::Flag.flag_types[:false_positive], origin: 'post analyzer X', description: 'static string to sink', finding: build(:vulnerabilities_finding))
      expect(flag).to be_valid
    end
  end
end
