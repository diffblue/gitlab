# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastProfileBranch'] do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('DastProfileBranch') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_field(:name, calls_gitaly?: true) }
  it { expect(described_class).to have_graphql_field(:exists, calls_gitaly?: true) }
end
