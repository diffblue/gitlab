# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::PreScanVerificationStep, :dynamic_analysis,
                                              feature_category: :dynamic_application_security_testing,
                                              type: :model do
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }

  subject { build(:dast_pre_scan_verification_step, dast_pre_scan_verification: dast_pre_scan_verification) }

  describe 'associations' do
    it { is_expected.to belong_to(:dast_pre_scan_verification).class_name('Dast::PreScanVerification').required }
  end

  describe 'enums' do
    let(:check_types) { { connection: 0, authentication: 1, crawling: 2 } }

    it { is_expected.to define_enum_for(:check_type).with_values(**check_types).with_prefix }
  end

  describe 'instance methods' do
    describe '#success?' do
      context 'when the verification_errors is an empty list' do
        before do
          subject.verification_errors = []
        end

        it { is_expected.to be_success }
      end

      context 'when the are verification errors' do
        before do
          subject.verification_errors = ['Actionable error message']
        end

        it { is_expected.not_to be_success }
      end
    end
  end
end
