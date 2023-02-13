# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::PreScanVerification, :dynamic_analysis,
  feature_category: :dynamic_application_security_testing,
  type: :model do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:dast_profile) { create(:dast_profile, project: project) }

  subject { create(:dast_pre_scan_verification, dast_profile: dast_profile) }

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:dast_profile_id) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'instance methods' do
    describe '#verification_valid?' do
      context 'when the associated dast_site_profile was updated before the pre_scan_verification creation' do
        before do
          subject.created_at = subject.created_at + 1.day
          subject.save!
        end

        it { is_expected.to be_verification_valid }
      end

      context 'when the associated dast_site_profile was updated after the pre_scan_verification creation' do
        before do
          subject.created_at = subject.created_at - 1.day
          subject.save!
        end

        it { is_expected.not_to be_verification_valid }
      end
    end
  end
end
