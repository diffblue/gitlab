# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceStandardsAdherenceStandard'], feature_category: :compliance_management do
  let(:fields) do
    %w[GITLAB]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceStandardsAdherenceStandard') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
