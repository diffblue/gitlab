# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EscalationRuleType'] do
  specify { expect(described_class.graphql_name).to eq('EscalationRuleType') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      oncall_schedule
      user
      elapsed_time_seconds
      status
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
