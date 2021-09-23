# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['VulnerabilityLink'] do
  let(:expected_fields) { %i[name url] }

  subject { described_class }

  it { is_expected.to have_graphql_fields(expected_fields) }
end
