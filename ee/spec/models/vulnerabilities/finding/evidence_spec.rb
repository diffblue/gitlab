# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence do
  it { is_expected.to validate_length_of(:summary).is_at_most(8_000_000) }
  it { is_expected.to validate_presence_of(:data) }
  it { is_expected.to validate_length_of(:data).is_at_most(16_000_000) }
end
