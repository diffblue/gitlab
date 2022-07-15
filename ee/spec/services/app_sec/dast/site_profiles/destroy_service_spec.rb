# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteProfiles::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_profile, reload: true) { create(:dast_site_profile) }

  let(:project) { dast_profile.project }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject do
      described_class.new(project, user).execute(
        id: dast_site_profile_id
      )
    end

    let(:dast_site_profile_id) { dast_profile.id }
    let(:status) { subject.status }
    let(:message) { subject.message }
    let(:payload) { subject.payload }

    context 'when a user does not have access to the project' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('You are not authorized to delete this site profile')
      end
    end

    context 'when the user can run a DAST scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'deletes the dast_site_profile' do
        expect { subject }.to change { DastSiteProfile.count }.by(-1)
      end

      it 'returns a dast_site_profile payload' do
        expect(payload).to be_a(DastSiteProfile)
      end

      it 'audits the deletion' do
        profile = payload

        audit_event = AuditEvent.find_by(author_id: user.id)

        aggregate_failures do
          expect(audit_event.author).to eq(user)
          expect(audit_event.entity).to eq(project)
          expect(audit_event.target_id).to eq(profile.id)
          expect(audit_event.target_type).to eq('DastSiteProfile')
          expect(audit_event.target_details).to eq(profile.name)
          expect(audit_event.details).to eq({
            author_name: user.name,
            author_class: user.class.name,
            custom_message: 'Removed DAST site profile',
            target_id: profile.id,
            target_type: 'DastSiteProfile',
            target_details: profile.name
          })
        end
      end

      context 'when the dast_site_profile does not exist' do
        let(:dast_site_profile_id) do
          Gitlab::GlobalId.build(nil, model_name: 'DastSiteProfile', id: 'does_not_exist')
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Site profile not found for given parameters')
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('You are not authorized to delete this site profile')
        end
      end

      include_examples 'restricts modification if referenced by policy', :delete
    end
  end
end
