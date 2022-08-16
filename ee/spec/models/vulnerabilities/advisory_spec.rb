# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vulnerabilities::Advisory, type: :model do
  using RSpec::Parameterized::TableSyntax

  subject(:advisory) { build(:vulnerability_advisory) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:created_date) }
    it { is_expected.to validate_presence_of(:published_date) }
    it { is_expected.to validate_presence_of(:uuid) }

    describe 'length validation' do
      where(:attribute, :max_length) do
        :title | 2048
        :affected_range | 32
        :not_impacted | 2048
        :solution | 2048
        :cvss_v2 | 128
        :cvss_v3 | 128
        :description | 2048
      end

      with_them do
        it { is_expected.to validate_length_of(attribute).is_at_most(max_length) }
      end
    end
  end
end
