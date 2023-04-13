# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::BaseScanner, feature_category: :software_composition_analysis do
  let(:project) { nil }
  let(:pipeline) { nil }

  subject(:scanner) { described_class.new(project, pipeline) }

  describe "#initialize" do
    it "returns a base scanner instance" do
      is_expected.to be_a_kind_of(described_class)
    end
  end

  describe "#report" do
    it "raises a not implemented error" do
      expect { scanner.report }.to raise_error(RuntimeError, /Must implement method in child class/)
    end
  end

  describe "#latest_pipeline" do
    it "raises a not implemented error" do
      expect do
        described_class.latest_pipeline(nil, nil)
      end.to raise_error(RuntimeError, /Must implement method in child class/)
    end
  end

  describe "#has_data?" do
    it "raises a not implemented error" do
      expect { scanner.has_data? }.to raise_error(RuntimeError, /Must implement method in child class/)
    end
  end

  describe "#results_available?" do
    it "raises a not implemented error" do
      expect { scanner.results_available? }.to raise_error(RuntimeError, /Must implement method in child class/)
    end
  end

  describe "#latest_build_for_default_branch" do
    it "raises a not implemented error" do
      expect do
        scanner.latest_build_for_default_branch
      end.to raise_error(RuntimeError, /Must implement method in child class/)
    end
  end
end
