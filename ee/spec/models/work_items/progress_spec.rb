# frozen_string_literal: true
require 'spec_helper'

RSpec.describe WorkItems::Progress do
  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
  end

  describe 'validations' do
    it "ensures progress is an integer greater than to equal to 0 and less than or equal to 100" do
      is_expected.to validate_numericality_of(:progress).only_integer.is_greater_than_or_equal_to(0)
                        .is_less_than_or_equal_to(100)
    end
  end
end
