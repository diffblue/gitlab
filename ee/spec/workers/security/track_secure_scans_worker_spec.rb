# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Security::TrackSecureScansWorker, feature_category: :vulnerability_management do
  let!(:ci_build) { create(:ee_ci_build) }

  describe '#perform' do
    subject { described_class.new.perform(ci_build.id) }

    context 'build is found' do
      it 'executes track service' do
        expect(Security::TrackScanService).to receive(:new).with(ci_build).and_call_original

        subject
      end
    end

    context 'build is not found' do
      let(:ci_build) { build(:ee_ci_build) }

      it 'skips track service' do
        expect(Security::TrackScanService).not_to receive(:new)

        subject
      end
    end
  end
end
