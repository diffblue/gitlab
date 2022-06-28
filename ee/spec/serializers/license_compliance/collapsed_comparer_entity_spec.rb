# frozen_string_literal: true
require 'spec_helper'

RSpec.describe LicenseCompliance::CollapsedComparerEntity do
  let(:entity) do
    described_class.new(
      ::Gitlab::Ci::Reports::LicenseScanning::ReportsComparer.new(
        project.license_compliance(base_pipeline),
        project.license_compliance(head_pipeline)
      ),
      request: request
    )
  end

  let_it_be(:project) { create_default(:project, :repository) }

  let_it_be(:base_pipeline) do
    create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)])
  end

  let_it_be(:head_pipeline) do
    create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)])
  end

  let(:request) { EntityRequest.new(approval_required: false, has_denied_licenses: false) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains the new, existing and removed license lists' do
      expect(subject).to have_key(:new_licenses)
      expect(subject).to have_key(:existing_licenses)
      expect(subject).to have_key(:removed_licenses)
      expect(subject).to have_key(:approval_required)
      expect(subject).to have_key(:has_denied_licenses)
    end
  end
end
