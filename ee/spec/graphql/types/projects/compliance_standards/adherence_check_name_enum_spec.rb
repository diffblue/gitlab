# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceStandardsAdherenceCheckName'], feature_category: :compliance_management do
  let(:fields) do
    %w[PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceStandardsAdherenceCheckName') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
