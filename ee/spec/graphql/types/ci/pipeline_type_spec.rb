# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Pipeline'] do
  it { expect(described_class.graphql_name).to eq('Pipeline') }

  it 'includes the ee specific fields' do
    expected_fields = %w[
      security_report_summary
      security_report_findings
      code_quality_reports
      dast_profile
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
