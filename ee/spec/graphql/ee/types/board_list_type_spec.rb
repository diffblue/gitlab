# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardList'] do
  it 'has specific fields' do
    expected_fields = %w[milestone iteration max_issue_count max_issue_weight assignee total_weight total_issue_weight]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
