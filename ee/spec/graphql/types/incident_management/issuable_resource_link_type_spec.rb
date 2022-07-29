# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['IssuableResourceLink'] do
  specify { expect(described_class.graphql_name).to eq('IssuableResourceLink') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_issuable_resource_link) }

  it 'exposes expected fields' do
    expected_fields = %i[
      id
      issue
      link
      link_text
      link_type
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
