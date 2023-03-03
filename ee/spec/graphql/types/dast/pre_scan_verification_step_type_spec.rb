# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastPreScanVerificationStep'], :dynamic_analysis,
                                                              feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }
  let_it_be(:object) do
    create(:dast_pre_scan_verification_step,
           check_type: 'connection',
           dast_pre_scan_verification: dast_pre_scan_verification,
           verification_errors: ['Actionable error message'])
  end

  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:fields) { %i[name check_type errors success] }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastPreScanVerificationStep') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'check_type field' do
    it 'correctly resolves the field' do
      expected_result = 'connection'

      expect(resolve_field(:check_type, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'errors field' do
    it 'correctly resolves the field' do
      expected_result = ['Actionable error message']

      expect(resolve_field(:errors, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'success field' do
    it 'correctly resolves the field' do
      expected_result = false

      expect(resolve_field(:success, object, current_user: user)).to eq(expected_result)
    end
  end
end
