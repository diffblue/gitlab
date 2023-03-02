# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CopyCrossDatabaseAssociationsService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:old_build) do
    create(:ci_build, pipeline: pipeline).tap do |build|
      build.update!(dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile)
    end
  end

  let(:new_build) { create(:ci_build, pipeline: pipeline) }

  describe '#execute' do
    subject(:execute) { described_class.new.execute(old_build, new_build) }

    context 'failure' do
      before do
        allow_next_instance_of(AppSec::Dast::Builds::AssociateService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'oops'))
        end
      end

      it 'returns an error response' do
        expect(execute).to have_attributes(status: :error)
      end

      it 'drops the build' do
        execute

        expect(new_build.reload).to be_failed
      end
    end

    context 'success' do
      it 'returns a success response' do
        expect(execute).to be_success
      end

      it 'clones the profile associations', :aggregate_failures do
        execute

        expect(new_build.dast_site_profile).to eq(dast_site_profile)
        expect(new_build.dast_scanner_profile).to eq(dast_scanner_profile)
        expect(new_build).not_to be_failed
      end
    end

    context 'when the job is not a build' do
      let_it_be(:old_build) { create(:ci_bridge, pipeline: pipeline) }

      it 'is successful' do
        expect(execute).to be_success
      end
    end
  end
end
