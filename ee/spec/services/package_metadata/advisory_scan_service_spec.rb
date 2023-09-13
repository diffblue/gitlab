# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AdvisoryScanService, feature_category: :software_composition_analysis do
  describe '.execute' do
    let(:advisory) { build(:pm_advisory) }

    it 'calls the advisory scanner execute method' do
      expect(::Gitlab::VulnerabilityScanning::AdvisoryScanner).to receive(:scan_projects_for).with(advisory)

      described_class.execute(advisory)
    end
  end
end
