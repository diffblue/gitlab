# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteTokens::FindOrCreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:target_url) { generate(:url) }

  subject do
    described_class.new(
      project: project,
      params: { target_url: target_url }
    ).execute
  end

  describe 'execute' do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        expect(subject).to have_attributes(status: :error, message: 'Insufficient permissions')
      end
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      it 'creates a new token' do
        expect { subject }.to change { DastSiteToken.count }.by(1)
      end

      it 'communicates success' do
        expect(subject).to have_attributes(status: :success, payload: { dast_site_token: instance_of(DastSiteToken), status: 'pending' })
      end

      context 'when the token already exists' do
        let_it_be(:dast_site_token) { create(:dast_site_token, project: project, url: target_url) }

        it 'does not create a new token' do
          expect { subject }.not_to change { DastSiteToken.count }
        end

        it 'includes it in the payload' do
          expect(subject).to have_attributes(status: :success, payload: hash_including(dast_site_token: dast_site_token))
        end

        context 'when an existing validation exists' do
          let_it_be(:dast_site_validation) { create(:dast_site_validation, dast_site_token: dast_site_token, state: :passed) }

          it 'includes its status in the payload' do
            expect(subject).to have_attributes(status: :success, payload: hash_including(status: dast_site_validation.state))
          end
        end
      end

      context 'when an invalid target_url is supplied' do
        let_it_be(:target_url) { 'http://bogus:broken' }

        it 'communicates failure' do
          expect(subject).to have_attributes(status: :error, message: 'Invalid target_url')
        end

        it 'does not create a dast_site_validation' do
          expect { subject }.to not_change { DastSiteValidation.count }
        end
      end
    end
  end
end
