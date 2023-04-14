# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceViolationInput'] do
  let(:arguments) do
    %w[projectIds mergedBefore mergedAfter targetBranch]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceViolationInput') }
  specify { expect(described_class.arguments.keys).to match_array(arguments) }
end
