# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComparableSecurityReportType'], feature_category: :vulnerability_management do
  let(:expected_enum_keys) do
    %w[
      SAST
      SECRET_DETECTION
      DAST
      CONTAINER_SCANNING
      DEPENDENCY_SCANNING
      COVERAGE_FUZZING
      API_FUZZING
    ]
  end

  it 'exposes all vulnerability report types' do
    expect(described_class.values.keys).to match_array(expected_enum_keys)
  end
end
