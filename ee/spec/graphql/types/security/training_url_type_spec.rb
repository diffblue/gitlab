# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityTrainingUrl'] do
  let(:fields) { %i[name url status identifier] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
