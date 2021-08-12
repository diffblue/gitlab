# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastProfileCadence'] do
  include GraphqlHelpers

  let_it_be(:fields) { %i[unit duration] }

  specify { expect(described_class.graphql_name).to eq('DastProfileCadence') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
