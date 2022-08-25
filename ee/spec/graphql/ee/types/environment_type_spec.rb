# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Environment'] do
  it 'includes the expected fields' do
    expected_fields = %w[protectedEnvironments]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
