# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::ArtifactScanner, feature_category: :license_compliance do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

  subject(:scanner) { described_class.new(project, pipeline) }

  describe "#report" do
    it "raises a not implemented error" do
      expect { scanner.report }.to raise_error(RuntimeError, /Not implemented/)
    end
  end

  describe "#latest_pipeline" do
    it "returns a pipeline" do
      expect(described_class.latest_pipeline(project, project.default_branch)).to eq(pipeline)
    end
  end

  describe "#has_data?" do
    it "raises a not implemented error" do
      expect { scanner.has_data? }.to raise_error(RuntimeError, /Not implemented/)
    end
  end

  describe "#results_available?" do
    it "raises a not implemented error" do
      expect { scanner.results_available? }.to raise_error(RuntimeError, /Not implemented/)
    end
  end
end
