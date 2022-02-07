# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Builds::AssociateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:params) do
    { ci_build_id: build.id, dast_site_profile_id: dast_site_profile.id, dast_scanner_profile_id: dast_scanner_profile.id }
  end

  describe '#execute' do
    subject(:execute) do
      described_class.new(params).execute
    end

    context 'params' do
      context 'when no keys are supplied' do
        let(:params) { {} }

        it 'returns a success response' do
          expect(execute).to be_success
        end
      end

      context 'when the ci_build_id key missing' do
        let(:params) do
          { dast_site_profile_id: dast_site_profile.id, dast_scanner_profile_id: dast_scanner_profile.id }
        end

        it 'returns an error response' do
          expect(execute).to have_attributes(status: :error, message: ['Ci build must exist', 'Ci build can\'t be blank'])
        end
      end
    end

    context 'success' do
      it 'returns a success response' do
        expect(execute).to be_success
      end

      it 'associates the site profile' do
        execute

        expect(build.reload.dast_site_profile).to eq(dast_site_profile)
      end

      it 'associates the scanner profile' do
        execute

        expect(build.reload.dast_scanner_profile).to eq(dast_scanner_profile)
      end

      it 'does not call any consistency workers' do
        expect(AppSec::Dast::SiteProfilesBuilds::ConsistencyWorker).not_to receive(:perform_async)
        expect(AppSec::Dast::ScannerProfilesBuilds::ConsistencyWorker).not_to receive(:perform_async)

        execute
      end
    end

    context 'error' do
      shared_examples 'an error' do
        it 'returns an error response' do
          expect(execute).to be_error
        end
      end

      shared_examples 'it attempts to maintain site profile association consistency' do
        it 'calls the site profile consistency worker' do
          expect(AppSec::Dast::SiteProfilesBuilds::ConsistencyWorker).to receive(:perform_async).with(build.id, dast_site_profile.id).and_call_original

          execute
        end
      end

      shared_examples 'it attempts to maintain scanner profile association consistency' do
        it 'calls the scanner profile consistency worker' do
          expect(AppSec::Dast::ScannerProfilesBuilds::ConsistencyWorker).to receive(:perform_async).with(build.id, dast_scanner_profile.id).and_call_original

          execute
        end
      end

      context 'when saving a SiteProfilesBuild fails' do
        before do
          stub_save_failure(::Dast::SiteProfilesBuild)
        end

        it_behaves_like 'an error'
        it_behaves_like 'it attempts to maintain site profile association consistency'
      end

      context 'when saving a ScannerProfilesBuild fails' do
        before do
          stub_save_failure(::Dast::ScannerProfilesBuild)
        end

        it_behaves_like 'an error'
        it_behaves_like 'it attempts to maintain scanner profile association consistency'
      end

      context 'when saving both associations fails' do
        before do
          stub_save_failure(::Dast::SiteProfilesBuild)
          stub_save_failure(::Dast::ScannerProfilesBuild)
        end

        it_behaves_like 'an error'
        it_behaves_like 'it attempts to maintain site profile association consistency'
        it_behaves_like 'it attempts to maintain scanner profile association consistency'
      end

      def stub_save_failure(klass)
        allow_next_instance_of(klass) do |instance|
          allow(instance).to receive(:save).and_return(false)
        end
      end
    end
  end
end
