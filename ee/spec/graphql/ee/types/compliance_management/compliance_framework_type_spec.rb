# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceFramework'] do
  subject { described_class }

  fields = %w[
    id
    name
    description
    color
    default
    pipeline_configuration_full_path
  ]

  it 'has the correct fields' do
    is_expected.to have_graphql_fields(fields)
  end
end
