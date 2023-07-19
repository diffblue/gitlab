# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceStandardsAdherenceInput'], feature_category: :compliance_management do
  let(:arguments) do
    %w[projectIds checkName standard]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceStandardsAdherenceInput') }
  specify { expect(described_class.arguments.keys).to match_array(arguments) }
end
