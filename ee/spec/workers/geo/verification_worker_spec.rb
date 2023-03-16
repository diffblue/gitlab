# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationWorker, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:package_file) { create(:conan_package_file, :conan_recipe_file) }
  let(:job_args) { ['package_file', package_file.id] }

  describe '#perform' do
    it 'calls verify' do
      replicator = double(:replicator)
      allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_params).with(replicable_name: 'package_file', replicable_id: package_file.id).and_return(replicator)

      expect(replicator).to receive(:verify)

      described_class.new.perform(*job_args)
    end

    context 'when on a primary node' do
      before do
        stub_primary_node
        package_file.verification_started!
      end

      it_behaves_like 'an idempotent worker' do
        it 'calculates the checksum' do
          described_class.new.perform(*job_args)

          expect(package_file.reload.verification_checksum).to eq('ee66543d50acf8dfe39cbc0bbd40d4a801e479ecf5f90ebef9f2321eeb4bf09b')
        end
      end
    end
  end
end
