# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteValidations::RunnerService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project] ) }
  let_it_be(:dast_site_token) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_validation) { create(:dast_site_validation, dast_site_token: dast_site_token) }

  subject do
    described_class.new(project: project, current_user: developer, params: { dast_site_validation: dast_site_validation }).execute
  end

  describe 'execute' do
    shared_examples 'a failure' do
      it 'communicates failure' do
        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when on demand scan licensed feature is not available' do
      before do
        stub_licensed_features(security_on_demand_scans: false)
      end

      it_behaves_like 'a failure'
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      it 'communicates success' do
        expect(subject).to have_attributes(status: :success, payload: dast_site_validation)
      end

      it 'creates a ci_pipeline with an appropriate source', :aggregate_failures do
        expect { subject }.to change { Ci::Pipeline.count }.by(1)

        expect(Ci::Pipeline.last.source).to eq('ondemand_dast_validation')
      end

      it 'makes the correct variables available to the ci_build' do
        subject

        build = Ci::Pipeline.last.builds.find_by(name: 'validation')

        expected_variables = {
          'DAST_SITE_VALIDATION_ID' => String(dast_site_validation.id),
          'DAST_SITE_VALIDATION_HEADER' => ::DastSiteValidation::HEADER,
          'DAST_SITE_VALIDATION_STRATEGY' => dast_site_validation.validation_strategy,
          'DAST_SITE_VALIDATION_TOKEN' => dast_site_validation.dast_site_token.token,
          'DAST_SITE_VALIDATION_URL' => dast_site_validation.validation_url
        }

        expect(build.variables.to_hash).to include(expected_variables)
      end

      context 'when pipeline creation fails' do
        before do
          allow_next_instance_of(Ci::Pipeline) do |instance|
            allow(instance).to receive(:created_successfully?).and_return(false)
            allow(instance).to receive(:full_error_messages).and_return('error message')
          end
        end

        it 'transitions the dast_site_validation to a failure state', :aggregate_failures do
          expect(dast_site_validation).to receive(:fail_op).and_call_original

          expect { subject }.to change { dast_site_validation.state }.from('pending').to('failed')
        end
      end
    end
  end
end
