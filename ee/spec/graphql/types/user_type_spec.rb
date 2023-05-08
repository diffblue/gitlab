# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['User'], feature_category: :user_profile do
  it 'has the expected fields' do
    expected_fields = %w[
      workspaces
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
