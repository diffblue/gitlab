# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelEnum'] do
  specify { expect(described_class.graphql_name).to eq('AccessLevelEnum') }

  it 'exposes all the existing EE access level values' do
    expect(described_class.values.keys).to include(*%w[ADMIN])
  end
end
