# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastPreScanVerificationStatus'], :dynamic_analysis, feature_category:
                                                                           :dynamic_application_security_testing do
  it 'exposes all alert field names' do
    expect(described_class.values.keys).to match_array(%w[RUNNING COMPLETE COMPLETE_WITH_ERRORS FAILED])
  end
end
