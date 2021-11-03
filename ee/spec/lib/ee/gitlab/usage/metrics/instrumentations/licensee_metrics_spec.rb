# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::LicenseeMetrics do
  let(:expected_value) do
    {
      "Name" => ::License.current.licensee_name,
      "Company" => ::License.current.licensee_company,
      "Email" => ::License.current.licensee_email
    }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
end
