# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComparedSecurityReportFinding'], feature_category: :vulnerability_management do
  let(:expected_fields) { %i[uuid title description state severity found_by_pipeline_iid location identifiers] }

  it { expect(described_class).to have_graphql_fields(expected_fields) }
end
