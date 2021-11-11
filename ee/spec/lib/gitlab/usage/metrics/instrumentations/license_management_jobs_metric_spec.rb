# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::LicenseManagementJobsMetric do
  before do
    create(:ci_build, name: :license_management)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'ruby' } do
    let(:expected_value) { 1 }
  end
end
