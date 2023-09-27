# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicensesListSerializer, feature_category: :dependency_management do
  describe '#to_json' do
    subject do
      described_class.new(project: project, user: user)
        .represent(license_compliance.policies, build: ci_build)
        .to_json
    end

    let(:project) { create(:project, :repository) }
    let!(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
    let(:license_compliance) { project.license_compliance }
    let(:user) { create(:user) }
    let(:ci_build) { create(:ee_ci_build, :success) }

    before do
      project.add_guest(user)
      stub_licensed_features(license_scanning: true)
    end

    it { is_expected.to match_schema('licenses_list', dir: 'ee') }
  end
end
