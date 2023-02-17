# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastPreScanVerification'], :dynamic_analysis,
                                                              feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:object) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_pre_scan_verification_step_1) do
    create(:dast_pre_scan_verification_step,
           check_type: 'connection',
           dast_pre_scan_verification: object)
  end

  let_it_be(:dast_pre_scan_verification_step_2) do
    create(:dast_pre_scan_verification_step,
           check_type: 'authentication',
           dast_pre_scan_verification: object,
           verification_errors: ['Actionable error message'])
  end

  let_it_be(:dast_pre_scan_verification_step_3) do
    create(:dast_pre_scan_verification_step,
           check_type: 'crawling',
           dast_pre_scan_verification: object)
  end

  let_it_be(:fields) { %i[preScanVerificationSteps status valid] }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastPreScanVerification') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'status field' do
    it 'correctly resolves the field' do
      expected_result = 'running'

      expect(resolve_field(:status, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'valid field' do
    it 'correctly resolves the field' do
      expected_result = true

      expect(resolve_field(:valid, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'preScanVerificationSteps field' do
    it 'correctly resolves the field' do
      expected_result = [dast_pre_scan_verification_step_1,
        dast_pre_scan_verification_step_2,
        dast_pre_scan_verification_step_3]

      expect(resolve_field(:preScanVerificationSteps, object, current_user: user)).to eq(expected_result)
    end
  end
end
