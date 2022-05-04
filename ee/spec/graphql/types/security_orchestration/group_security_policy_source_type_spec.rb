# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GroupSecurityPolicySource'] do
  let(:fields) { %i[namespace inherited] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
