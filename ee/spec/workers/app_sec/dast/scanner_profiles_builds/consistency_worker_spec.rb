# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ScannerProfilesBuilds::ConsistencyWorker, feature_category: :dynamic_application_security_testing do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:build) { create(:ci_build, project: project) }
    let_it_be(:profile) { create(:dast_scanner_profile, project: project) }

    let(:job_args) { [build.id, profile.id] }

    it 'ensures cross database association is created', :aggregate_failures do
      expect { worker.perform(*job_args) }.to change { Dast::ScannerProfilesBuild.count }.by(1)

      expect(Dast::ScannerProfilesBuild.where(ci_build_id: build.id, dast_scanner_profile_id: profile.id)).to exist
    end

    it_behaves_like 'an idempotent worker'
  end
end
