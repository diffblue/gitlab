# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IncidentManagement::IssuableResourceLinkTypeEnum do
  specify { expect(described_class.graphql_name).to eq('IssuableResourceLinkType') }

  it 'exposes all the existing issuable resource link types values' do
    expect(described_class.values.keys).to contain_exactly(
      *%w[general zoom slack pagerduty]
    )
  end
end
