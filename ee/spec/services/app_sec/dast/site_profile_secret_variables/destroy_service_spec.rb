# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::SiteProfileSecretVariables::DestroyService do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile_secret_variable, refind: true) { create(:dast_site_profile_secret_variable, dast_site_profile: dast_site_profile) }

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: { dast_site_profile_secret_variable: dast_site_profile_secret_variable }
    ).execute
  end

  describe '#execute' do
    context 'when on demand scan licensed feature is not available' do
      it 'communicates failure' do
        stub_licensed_features(security_on_demand_scans: false)

        expect(subject).to have_attributes(
          status: :error,
          message: 'Insufficient permissions'
        )
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the user cannot destroy a DAST site profile secret variable' do
        it 'communicates failure' do
          expect(subject).to have_attributes(
            status: :error,
            message: 'Insufficient permissions'
          )
        end
      end

      context 'when the user can destroy a DAST site profile secret variable' do
        before do
          project.add_developer(user)
        end

        it 'returns a success status' do
          expect(subject.status).to eq(:success)
        end

        it 'deletes the dast_site_profile_secret_variable' do
          expect { subject }.to change { Dast::SiteProfileSecretVariable.count }.by(-1)
        end

        it 'returns a dast_site_profile_secret_variable payload' do
          expect(subject.payload).to be_a(Dast::SiteProfileSecretVariable)
        end

        context 'when the dast_site_profile_secret_variable fails to destroy' do
          it 'communicates failure' do
            allow(dast_site_profile_secret_variable).to receive(:destroy).and_return(false)

            expect(subject).to have_attributes(
              status: :error,
              message: 'Variable failed to delete'
            )
          end
        end

        context 'when the dast_site_profile_secret_variable parameter is missing' do
          let(:dast_site_profile_secret_variable) { nil }

          it 'communicates failure' do
            expect(subject).to have_attributes(
              status: :error,
              message: 'Variable parameter missing'
            )
          end
        end
      end
    end
  end
end
