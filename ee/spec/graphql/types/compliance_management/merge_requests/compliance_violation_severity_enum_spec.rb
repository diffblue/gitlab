# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceViolationSeverity'] do
  let_it_be(:fields) do
    ::Enums::MergeRequests::ComplianceViolation.severity_levels.keys.map { |s| s.to_s.upcase }
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceViolationSeverity') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
