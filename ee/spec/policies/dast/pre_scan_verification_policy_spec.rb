# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::PreScanVerificationPolicy, :dynamic_analysis,
  feature_category: :dynamic_application_security_testing do
  it_behaves_like 'a dast on-demand scan policy' do
    let_it_be(:dast_profile) { create(:dast_profile, project: project) }
    let_it_be(:record) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }
  end
end
