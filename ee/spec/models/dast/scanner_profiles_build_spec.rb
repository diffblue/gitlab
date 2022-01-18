# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ScannerProfilesBuild, type: :model do
  subject { create(:dast_scanner_profiles_build) }

  describe 'associations' do
    it { is_expected.to belong_to(:ci_build).class_name('Ci::Build').required }
    it { is_expected.to belong_to(:dast_scanner_profile).class_name('DastScannerProfile').required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:ci_build_id) }
    it { is_expected.to validate_presence_of(:dast_scanner_profile_id) }

    context 'when the ci_build.project_id and dast_scanner_profile.project_id do not match' do
      let(:ci_build) { build(:ci_build, project_id: 1) }
      let(:scanner_profile) { build(:dast_scanner_profile, project_id: 2) }

      subject { build(:dast_scanner_profiles_build, ci_build: ci_build, dast_scanner_profile: scanner_profile) }

      it 'is not valid', :aggregate_failures do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include('Ci build project_id must match dast_scanner_profile.project_id')
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:dast_scanner_profiles_build) }
    let(:parent) { model.ci_build }
  end
end
