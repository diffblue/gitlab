# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceViolationSort'] do
  let(:fields) do
    %w[
      SEVERITY_LEVEL_DESC SEVERITY_LEVEL_ASC VIOLATION_REASON_DESC VIOLATION_REASON_ASC
      MERGE_REQUEST_TITLE_DESC MERGE_REQUEST_TITLE_ASC MERGED_AT_DESC MERGED_AT_ASC
    ]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceViolationSort') }
  specify { expect(described_class.values.keys).to match_array(fields) }
end
