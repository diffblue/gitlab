# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VulnerabilityContainerImage'] do
  let(:expected_fields) { %i[name] }

  subject { described_class }

  it { is_expected.to have_graphql_fields(expected_fields) }
end
