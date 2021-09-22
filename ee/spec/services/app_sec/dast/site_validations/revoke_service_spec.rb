# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteValidations::RevokeService do
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_site_token) { create(:dast_site_token, project: project) }
  let_it_be(:common_url_base) { DastSiteValidation.get_normalized_url_base(dast_site_token.url) }

  let_it_be(:dast_site_validation_other_project) { create(:dast_site_validation, dast_site_token: create(:dast_site_token, url: common_url_base)) }
  let_it_be(:dast_site_validation_other_url) { create(:dast_site_validation, dast_site_token: create(:dast_site_token, project: project)) }

  let_it_be(:external_dast_site_validations) do
    [dast_site_validation_other_project, dast_site_validation_other_url]
  end

  let_it_be(:dast_site_validations) do
    DastSiteValidation.state_machine.states.map do |state|
      create(:dast_site_validation, state: state.name, dast_site_token: dast_site_token)
    end
  end

  let(:params) { { url_base: common_url_base } }

  subject { described_class.new(container: project, params: params).execute }

  describe 'execute', :clean_gitlab_redis_shared_state do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      it 'communicates success' do
        expect(subject.status).to eq(:success)
      end

      it 'deletes only dast_site_validation validations in the same project that share a common url_base', :aggregate_failures do
        total = dast_site_validations.size + external_dast_site_validations.size
        delta = external_dast_site_validations.size

        expect { subject }.to change { DastSiteValidation.count }.from(total).to(delta)

        dast_site_validations.each do |dast_site_validation|
          expect { dast_site_validation.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        external_dast_site_validations.each do |dast_site_validation|
          expect { dast_site_validation_other_project.reload }.not_to raise_error
        end
      end

      it 'returns a count of the dast_site_validations that were deleted' do
        expect(subject.payload[:count]).to eq(dast_site_validations.size)
      end

      context 'when the finder does not find any dast_site_validations' do
        let_it_be(:project) { create(:project) }

        it 'communicates success' do
          expect(subject.status).to eq(:success)
        end

        it 'is a noop' do
          aggregate_failures do
            expect(subject.payload[:count]).to be_zero

            expect { subject }.not_to change { DastSiteValidation.count }
          end
        end
      end

      context 'when a param is missing' do
        let(:params) { {} }

        it 'communicates failure' do
          aggregate_failures do
            expect(subject.status).to eq(:error)
            expect(subject.message).to eq('URL parameter used to search for validations is missing')
          end
        end
      end
    end
  end
end
