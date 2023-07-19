# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceStandardsAdherenceStatus'], feature_category: :compliance_management do
  let(:fields) do
    %w[SUCCESS FAIL]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceStandardsAdherenceStatus') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
