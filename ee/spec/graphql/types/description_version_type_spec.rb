# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DescriptionVersion'], feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      description
      diff
      diff_path
      delete_path
      can_delete
      deleted
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
