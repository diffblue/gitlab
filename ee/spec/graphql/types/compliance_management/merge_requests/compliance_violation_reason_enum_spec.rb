# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceViolationReason'] do
  let_it_be(:fields) do
    ::Enums::MergeRequests::ComplianceViolation.reasons.keys.map { |r| r.to_s.upcase }
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceViolationReason') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
