# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectSecurityPolicySource'] do
  let(:fields) { %i[project] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
