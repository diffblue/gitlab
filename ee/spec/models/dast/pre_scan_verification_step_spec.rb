# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::PreScanVerificationStep, :dynamic_analysis,
                                              feature_category: :dynamic_application_security_testing,
                                              type: :model do
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: dast_profile) }

  let_it_be(:valid_steps) { %w[connection authentication crawling] }

  subject do
    build(:dast_pre_scan_verification_step, name: 'connection', dast_pre_scan_verification: dast_pre_scan_verification)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dast_pre_scan_verification).class_name('Dast::PreScanVerification').required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it {
      is_expected.to validate_inclusion_of(:name).in_array(valid_steps).with_message('is not a valid pre step name')
    }
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
