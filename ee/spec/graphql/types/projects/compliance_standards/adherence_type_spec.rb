# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComplianceStandardsAdherence'], feature_category: :compliance_management do
  let(:fields) do
    %i[id updated_at status check_name standard project]
  end

  specify { expect(described_class.graphql_name).to eq('ComplianceStandardsAdherence') }
  specify { expect(described_class).to have_graphql_fields(fields) }
  specify { expect(described_class).to require_graphql_authorizations(:read_group_compliance_dashboard) }
end
