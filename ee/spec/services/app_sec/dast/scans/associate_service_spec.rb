# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Scans::AssociateService, feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, :with_dast_submit_field, project: project) }

  let_it_be(:dast_scanner_profile) do
    create(:dast_scanner_profile, project: project, spider_timeout: 42, target_timeout: 21)
  end

  let_it_be(:dast_profile) do
    create(:dast_profile,
      project: project,
      dast_site_profile: dast_site_profile,
      dast_scanner_profile: dast_scanner_profile
    )
  end

  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:params) { { pipeline: pipeline, dast_profile: dast_profile } }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject(:execute) do
      described_class.new(project, user).execute(**params)
    end

    context 'when user is not allowed to create on demand scans' do
      it 'does not associate the dast_profile and the ci_pipeline', :aggregate_failures do
        expect do
          expect(subject).to be_error.and have_attributes(message: 'Insufficient permissions')
        end.not_to change { pipeline.reload.dast_profile }
      end
    end

    context 'when user is allowed to create on demand scans' do
      before_all do
        project.add_developer(user)
      end

      it 'associates the dast_profile and the ci_pipeline', :aggregate_failures do
        expect do
          expect(subject).to be_success
        end.to change { pipeline.reload.dast_profile }.from(nil).to(dast_profile)
      end

      context 'when an association already exists' do
        before do
          ::Dast::ProfilesPipeline.create!(ci_pipeline_id: pipeline.id, dast_profile_id: dast_profile.id)
        end

        it 'is idempotent', :aggregate_failures do
          expect do
            expect(subject).to be_success
          end.not_to change { pipeline.reload.dast_profile }
        end
      end
    end
  end
end
