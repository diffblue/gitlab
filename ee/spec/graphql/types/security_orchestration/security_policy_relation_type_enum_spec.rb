# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityPolicyRelationType'] do
  specify { expect(described_class.graphql_name).to eq('SecurityPolicyRelationType') }

  it 'exposes all policy relation types' do
    expect(described_class.values.keys).to include(*%w[DIRECT INHERITED INHERITED_ONLY])
  end
end
