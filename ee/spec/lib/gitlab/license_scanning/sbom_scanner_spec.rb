# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::SbomScanner, feature_category: :license_compliance do
  let(:project) { nil }
  let(:pipeline) { nil }

  subject(:scanner) { described_class.new(project, pipeline) }

  describe "#report" do
    it "raises a not implemented error" do
      expect { scanner.report }.to raise_error(RuntimeError, /Not implemented/)
    end
  end

  describe "#latest_pipeline" do
    it "raises a not implemented error" do
      expect do
        described_class.latest_pipeline(nil, nil)
      end.to raise_error(RuntimeError, /Not implemented/)
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
