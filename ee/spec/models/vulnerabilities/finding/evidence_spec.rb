# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence, feature_category: :vulnerability_management do
  it { is_expected.to validate_presence_of(:data) }
  it { is_expected.to validate_length_of(:data).is_at_most(16_000_000) }
end
