# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AdvisoryScanService, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:advisory) { build(:pm_advisory) }

    it 'is not implemented' do
      expect { described_class.execute(advisory) }.to raise_error(NoMethodError)
    end
  end
end
