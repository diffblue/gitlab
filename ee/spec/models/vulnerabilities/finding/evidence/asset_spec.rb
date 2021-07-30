# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::Asset do
  it { is_expected.to belong_to(:evidence).class_name('Vulnerabilities::Finding::Evidence').inverse_of(:assets).required }

  it { is_expected.to validate_length_of(:type).is_at_most(2048) }
  it { is_expected.to validate_length_of(:name).is_at_most(2048) }
  it { is_expected.to validate_length_of(:url).is_at_most(2048) }

  it_behaves_like 'validates presence of any field'
end
