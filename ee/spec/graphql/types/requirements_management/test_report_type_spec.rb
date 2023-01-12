# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TestReport'] do
  fields = %i[id state author created_at uses_legacy_iid]

  it { expect(described_class.graphql_name).to eq('TestReport') }

  it { expect(described_class).to have_graphql_fields(fields) }
end
