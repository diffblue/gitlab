# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastProfileScheduleInput'] do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('DastProfileScheduleInput') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[active startsAt timezone cadence])
  end
end
